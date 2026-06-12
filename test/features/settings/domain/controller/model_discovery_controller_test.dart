import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/features/home/data/datasource/ollama_datasource.dart';
import 'package:crm/features/settings/data/datasource/huggingface_datasource.dart';
import 'package:crm/features/settings/domain/controller/model_discovery_controller.dart';
import 'package:crm/features/settings/domain/model/download_status.dart';
import 'package:crm/features/settings/domain/model/fit_scorer.dart';
import 'package:crm/features/settings/domain/model/hardware_info.dart';
import 'package:crm/features/settings/domain/model/huggingface_model_result.dart';
import 'package:crm/features/settings/domain/model/model_discovery_state.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/repository/hardware_info_repository.dart';

class FakeHuggingFaceDatasource implements HuggingFaceDatasource {
  final List<HuggingFaceModelResult> defaultResults;
  final Map<String, List<HuggingFaceModelResult>> resultsByQuery;
  final List<String?> queries = [];

  FakeHuggingFaceDatasource({
    this.defaultResults = const [],
    this.resultsByQuery = const {},
  });

  @override
  Future<List<HuggingFaceModelResult>> searchModels({String? query}) async {
    queries.add(query);
    if (query != null && query.isNotEmpty) {
      return resultsByQuery[query] ?? [];
    }
    return defaultResults;
  }
}

class FakeHardwareInfoRepository implements HardwareInfoRepository {
  final HardwareInfo hardware;
  int detectCalls = 0;

  FakeHardwareInfoRepository(this.hardware);

  @override
  Future<HardwareInfo> detect() async {
    detectCalls++;
    return hardware;
  }
}

const _hardware = HardwareInfo(
  gpuName: 'NVIDIA GeForce RTX 4090',
  vramTotalMb: 24576,
  vramAvailableMb: 22528,
  cudaAvailable: true,
  ramTotalMb: 32000,
  ramAvailableMb: 16000,
  cpuCores: 16,
);

const _defaultResult = HuggingFaceModelResult(
  repoId: 'TheBloke/Llama-2-7B-Chat-GGUF',
  displayName: 'Llama-2-7B-Chat-GGUF',
  paramsBillions: 7.0,
  quant: 'Q4_K_M',
  fileSizeBytes: 4081004224,
  contextLength: 4096,
);

const _llamaResult = HuggingFaceModelResult(
  repoId: 'TheBloke/Llama-2-13B-Chat-GGUF',
  displayName: 'Llama-2-13B-Chat-GGUF',
  paramsBillions: 13.0,
  quant: 'Q5_K_M',
  fileSizeBytes: 9000000000,
  contextLength: 4096,
);

const _ollamaCard = ServiceCard(
  id: 'ollama-1',
  category: ServiceCategory.localLlm,
  type: ServiceType.ollama,
  name: 'Ollama',
  fields: {'baseUrl': 'http://localhost:11434'},
);

const _ollamaCard2 = ServiceCard(
  id: 'ollama-2',
  category: ServiceCategory.localLlm,
  type: ServiceType.ollama,
  name: 'Ollama (remote)',
  fields: {'baseUrl': 'http://remote:11434'},
);

const _defaultOllamaCard = ServiceCard(
  id: 'ollama-default',
  category: ServiceCategory.localLlm,
  type: ServiceType.ollama,
  name: 'Ollama (default)',
  fields: {'baseUrl': 'http://localhost:11434'},
  isDefault: true,
);

/// A minimal [HttpClientAdapter] that returns a canned [ResponseBody] for
/// every request, computed by [handler].
class _FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Builds an [OllamaDatasource] whose `pullModel()` streams [lines] (each a
/// JSON-encoded NDJSON progress line) as a 200 response.
OllamaDatasource _fakeOllamaDatasource(List<String> lines) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:11434'));
  dio.httpClientAdapter = _FakeAdapter((options) {
    return ResponseBody.fromString(
      lines.join('\n'),
      200,
      headers: {Headers.contentTypeHeader: ['application/x-ndjson']},
    );
  });
  return OllamaDatasource(dio);
}

/// Builds an [OllamaDatasource] whose `pullModel()` fails with [statusCode]
/// and an `{"error": message}` JSON body.
OllamaDatasource _failingOllamaDatasource(int statusCode, String message) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:11434'));
  dio.httpClientAdapter = _FakeAdapter((options) {
    return ResponseBody.fromString(
      '{"error": "$message"}',
      statusCode,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  });
  return OllamaDatasource(dio);
}

void main() {
  group('ModelDiscoveryController', () {
    test('load() populates hardware and default results, each carrying a ModelFitResult',
        () async {
      final datasource = FakeHuggingFaceDatasource(defaultResults: const [_defaultResult]);
      final hardwareRepo = FakeHardwareInfoRepository(_hardware);
      final controller = ModelDiscoveryController(datasource, hardwareRepo);

      await controller.load();

      expect(controller.data!.hardware, _hardware);
      expect(controller.data!.results, hasLength(1));

      final result = controller.data!.results.single;
      expect(result.model, _defaultResult);

      final expectedFit = FitScorer.score(
        hardware: _hardware,
        paramsBillions: _defaultResult.paramsBillions,
        quant: _defaultResult.quant,
      );
      expect(result.fit.vramEstimateMb, expectedFit.vramEstimateMb);
      expect(result.fit.fit, expectedFit.fit);
      expect(result.fit.mode, expectedFit.mode);
      expect(result.fit.score, expectedFit.score);
      expect(result.fit.speedTokensPerSec, expectedFit.speedTokensPerSec);

      expect(hardwareRepo.detectCalls, 1);
      expect(datasource.queries, [null]);

      controller.dispose();
    });

    test('search(query) replaces results while keeping the already-detected hardware', () async {
      final datasource = FakeHuggingFaceDatasource(
        defaultResults: const [_defaultResult],
        resultsByQuery: {'llama': const [_llamaResult]},
      );
      final hardwareRepo = FakeHardwareInfoRepository(_hardware);
      final controller = ModelDiscoveryController(datasource, hardwareRepo);

      await controller.load();
      await controller.search('llama');

      expect(controller.data!.results, hasLength(1));
      expect(controller.data!.results.single.model, _llamaResult);
      expect(controller.data!.hardware, _hardware);
      expect(datasource.queries, [null, 'llama']);
      // hardware detection is not re-run on search.
      expect(hardwareRepo.detectCalls, 1);

      controller.dispose();
    });

    test('load() sorts results by fit score descending', () async {
      // _defaultResult (7B Q4_K_M) and _llamaResult (13B Q5_K_M) both fit
      // comfortably on _hardware ("perfect"), but the smaller model scores
      // higher within the same fit tier.
      final datasource = FakeHuggingFaceDatasource(
        defaultResults: const [_llamaResult, _defaultResult],
      );
      final hardwareRepo = FakeHardwareInfoRepository(_hardware);
      final controller = ModelDiscoveryController(datasource, hardwareRepo);

      await controller.load();

      final results = controller.data!.results;
      expect(results, hasLength(2));

      // Sorted descending by score.
      for (var i = 0; i < results.length - 1; i++) {
        expect(results[i].fit.score, greaterThanOrEqualTo(results[i + 1].fit.score));
      }

      // The smaller model (7B) should score higher than the larger one
      // (13B) since both land in the same "perfect" fit tier.
      expect(results.first.model, _defaultResult);
      expect(results.last.model, _llamaResult);

      controller.dispose();
    });

    test('search(query) sorts results by fit score descending', () async {
      final datasource = FakeHuggingFaceDatasource(
        resultsByQuery: {'llama': const [_llamaResult, _defaultResult]},
      );
      final hardwareRepo = FakeHardwareInfoRepository(_hardware);
      final controller = ModelDiscoveryController(datasource, hardwareRepo);

      await controller.load();
      await controller.search('llama');

      final results = controller.data!.results;
      expect(results, hasLength(2));
      for (var i = 0; i < results.length - 1; i++) {
        expect(results[i].fit.score, greaterThanOrEqualTo(results[i + 1].fit.score));
      }
      expect(results.first.model, _defaultResult);
      expect(results.last.model, _llamaResult);

      controller.dispose();
    });
  });

  group('ModelDiscoveryController.resolveOllamaCard()', () {
    test('returns none when no Ollama card is configured', () async {
      final controller = ModelDiscoveryController(
        FakeHuggingFaceDatasource(defaultResults: const [_defaultResult]),
        FakeHardwareInfoRepository(_hardware),
        ollamaCards: const [],
      );
      await controller.load();

      expect(controller.resolveOllamaCard(), isA<OllamaCardResolutionNone>());
      expect(controller.hasResolvableOllamaCard, isFalse);

      controller.dispose();
    });

    test('returns the sole Ollama card when exactly one exists', () async {
      final controller = ModelDiscoveryController(
        FakeHuggingFaceDatasource(defaultResults: const [_defaultResult]),
        FakeHardwareInfoRepository(_hardware),
        ollamaCards: const [_ollamaCard],
      );
      await controller.load();

      final resolution = controller.resolveOllamaCard();
      expect(resolution, isA<OllamaCardResolutionResolved>());
      expect((resolution as OllamaCardResolutionResolved).card, _ollamaCard);
      expect(controller.hasResolvableOllamaCard, isTrue);

      controller.dispose();
    });

    test('returns the Default-marked card when multiple Ollama cards exist', () async {
      final controller = ModelDiscoveryController(
        FakeHuggingFaceDatasource(defaultResults: const [_defaultResult]),
        FakeHardwareInfoRepository(_hardware),
        ollamaCards: const [_ollamaCard2, _defaultOllamaCard],
      );
      await controller.load();

      final resolution = controller.resolveOllamaCard();
      expect(resolution, isA<OllamaCardResolutionResolved>());
      expect((resolution as OllamaCardResolutionResolved).card, _defaultOllamaCard);

      controller.dispose();
    });

    test('returns ambiguous candidates when multiple Ollama cards exist and none is Default', () async {
      final controller = ModelDiscoveryController(
        FakeHuggingFaceDatasource(defaultResults: const [_defaultResult]),
        FakeHardwareInfoRepository(_hardware),
        ollamaCards: const [_ollamaCard, _ollamaCard2],
      );
      await controller.load();

      final resolution = controller.resolveOllamaCard();
      expect(resolution, isA<OllamaCardResolutionAmbiguous>());
      expect((resolution as OllamaCardResolutionAmbiguous).candidates, [_ollamaCard, _ollamaCard2]);
      expect(controller.hasResolvableOllamaCard, isFalse);

      controller.dispose();
    });
  });

  group('ModelDiscoveryController.download()', () {
    test('transitions a result through idle -> downloading -> added on a successful pull', () async {
      final lines = [
        jsonEncode({'status': 'pulling manifest'}),
        jsonEncode({'status': 'pulling abc123', 'total': 1000, 'completed': 500}),
        jsonEncode({'status': 'pulling abc123', 'total': 1000, 'completed': 1000}),
        jsonEncode({'status': 'success'}),
      ];

      final controller = ModelDiscoveryController(
        FakeHuggingFaceDatasource(defaultResults: const [_defaultResult]),
        FakeHardwareInfoRepository(_hardware),
        ollamaCards: const [_ollamaCard],
        ollamaDatasourceFor: (card) => _fakeOllamaDatasource(lines),
      );
      await controller.load();

      final result = controller.data!.results.single;
      expect(result.downloadStatus, isA<DownloadStatusIdle>());

      final statuses = <DownloadStatus>[];
      final subscription = controller.stream.listen((state) {
        if (state is AsyncData<ModelDiscoveryState>) {
          statuses.add(state.data.results.single.downloadStatus);
        }
      });

      await controller.download(result);
      await subscription.cancel();

      // Hardware and the other result-level fields are untouched.
      expect(controller.data!.hardware, _hardware);
      expect(controller.data!.results.single.model, _defaultResult);

      final finalStatus = controller.data!.results.single.downloadStatus;
      expect(finalStatus, isA<DownloadStatusAdded>());

      // Saw at least one "downloading" status with byte progress along the way.
      final progressWithBytes = statuses
          .whereType<DownloadStatusDownloading>()
          .map((s) => s.progress)
          .where((p) => p.completedBytes != null)
          .toList();
      expect(progressWithBytes, isNotEmpty);
      expect(progressWithBytes.last.completedBytes, 1000);
      expect(progressWithBytes.last.totalBytes, 1000);

      // The final "success" line is also surfaced as a "downloading" status
      // before the controller transitions to "added".
      expect(
        statuses.whereType<DownloadStatusDownloading>().last.progress.status,
        'success',
      );

      controller.dispose();
    });

    test('uses the explicitly passed card when ambiguous, without prompting', () async {
      final lines = [jsonEncode({'status': 'success'})];
      ServiceCard? usedCard;

      final controller = ModelDiscoveryController(
        FakeHuggingFaceDatasource(defaultResults: const [_defaultResult]),
        FakeHardwareInfoRepository(_hardware),
        ollamaCards: const [_ollamaCard, _ollamaCard2],
        ollamaDatasourceFor: (card) {
          usedCard = card;
          return _fakeOllamaDatasource(lines);
        },
      );
      await controller.load();

      final result = controller.data!.results.single;
      await controller.download(result, card: _ollamaCard2);

      expect(usedCard, _ollamaCard2);
      expect(controller.data!.results.single.downloadStatus, isA<DownloadStatusAdded>());

      controller.dispose();
    });

    test('sets a failed status with a "no Ollama card configured" message when none exists', () async {
      final controller = ModelDiscoveryController(
        FakeHuggingFaceDatasource(defaultResults: const [_defaultResult]),
        FakeHardwareInfoRepository(_hardware),
        ollamaCards: const [],
      );
      await controller.load();

      final result = controller.data!.results.single;
      await controller.download(result);

      final status = controller.data!.results.single.downloadStatus;
      expect(status, isA<DownloadStatusFailed>());
      expect((status as DownloadStatusFailed).message, contains('No Ollama'));

      controller.dispose();
    });

    test('a failed pull surfaces a failed status with the mapped error message', () async {
      final controller = ModelDiscoveryController(
        FakeHuggingFaceDatasource(defaultResults: const [_defaultResult]),
        FakeHardwareInfoRepository(_hardware),
        ollamaCards: const [_ollamaCard],
        ollamaDatasourceFor: (card) =>
            _failingOllamaDatasource(404, 'pull model manifest: file does not exist'),
      );
      await controller.load();

      final result = controller.data!.results.single;
      await controller.download(result);

      final status = controller.data!.results.single.downloadStatus;
      expect(status, isA<DownloadStatusFailed>());
      expect((status as DownloadStatusFailed).message, 'pull model manifest: file does not exist');

      // Hardware and other state untouched.
      expect(controller.data!.hardware, _hardware);

      controller.dispose();
    });
  });
}
