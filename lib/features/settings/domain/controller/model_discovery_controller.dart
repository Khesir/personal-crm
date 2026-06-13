import 'package:crm/core/state/state.dart';
import 'package:crm/features/home/data/datasource/ollama_datasource.dart';
import 'package:crm/features/home/domain/model/ollama_pull_progress.dart';
import 'package:crm/features/home/domain/repository/chat_model_repository.dart';
import 'package:crm/features/settings/data/repository/health_check_repository_impl.dart';
import 'package:crm/features/settings/domain/model/health_status.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/repository/health_check_repository.dart';
import 'package:dio/dio.dart';

import '../../data/datasource/huggingface_datasource.dart';
import '../model/download_status.dart';
import '../model/fit_scorer.dart';
import '../model/hardware_info.dart';
import '../model/huggingface_download.dart';
import '../model/huggingface_model_result.dart';
import '../model/model_discovery_result.dart';
import '../model/model_discovery_state.dart';
import '../repository/hardware_info_repository.dart';
import 'huggingface_download_tracker.dart';

/// Drives the "Search Hugging Face" dialog: detects local hardware and
/// searches Hugging Face for GGUF models.
class ModelDiscoveryController extends StreamState<AsyncState<ModelDiscoveryState>> {
  final HuggingFaceDatasource datasource;
  final HardwareInfoRepository hardwareRepository;

  /// The currently configured Ollama service cards (loaded once when this
  /// controller is created — see `createModelDiscoveryController`). Used by
  /// [resolveOllamaCard] to determine whether/where [download] can run.
  final List<ServiceCard> ollamaCards;

  /// Builds an [OllamaDatasource] for a chosen Ollama [ServiceCard]. Injected
  /// so tests can supply a fake; defaults to a real `Dio`-backed datasource
  /// pointed at the card's `fields['baseUrl']`.
  final OllamaDatasource Function(ServiceCard card) ollamaDatasourceFor;

  /// Tracks download status across "Search Hugging Face" dialog
  /// open/close — see [HuggingFaceDownloadTracker]. Injected so tests can
  /// supply a fresh instance; defaults to the app-lifetime singleton.
  final HuggingFaceDownloadTracker downloadTracker;

  /// Checks reachability of an Ollama [ServiceCard] before [download] starts
  /// pulling. Injected so tests can supply a fake; defaults to
  /// [HealthCheckRepositoryImpl].
  final HealthCheckRepository healthCheckRepository;

  ModelDiscoveryController(
    this.datasource,
    this.hardwareRepository, {
    this.ollamaCards = const [],
    OllamaDatasource Function(ServiceCard card)? ollamaDatasourceFor,
    HuggingFaceDownloadTracker? downloadTracker,
    HealthCheckRepository? healthCheckRepository,
  })  : ollamaDatasourceFor = ollamaDatasourceFor ?? _defaultOllamaDatasourceFor,
        downloadTracker = downloadTracker ?? HuggingFaceDownloadTracker.instance,
        healthCheckRepository = healthCheckRepository ?? HealthCheckRepositoryImpl(),
        super(const AsyncLoading());

  static OllamaDatasource _defaultOllamaDatasourceFor(ServiceCard card) {
    return OllamaDatasource(Dio(BaseOptions(
      baseUrl: card.fields['baseUrl'] ?? '',
      connectTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    )));
  }

  /// Detects hardware and runs an empty-query search. Called on dialog open;
  /// detection is not cached and re-runs every time.
  Future<void> load() => execute(() async {
        final hardware = await hardwareRepository.detect();
        final results = await datasource.searchModels();
        return ModelDiscoveryState(hardware: hardware, results: _withFit(hardware, results));
      });

  /// Re-queries Hugging Face with [query], replacing [ModelDiscoveryState.results]
  /// while keeping the already-detected hardware.
  Future<void> search(String query) {
    // Captured before `execute` emits AsyncLoading (which clears `data`).
    final previousHardware = data?.hardware;
    return execute(() async {
      final hardware = previousHardware ?? await hardwareRepository.detect();
      final results = await datasource.searchModels(query: query);
      return ModelDiscoveryState(hardware: hardware, results: _withFit(hardware, results));
    });
  }

  /// Scores each result against [hardware] via [FitScorer] and sorts the
  /// resulting list by [ModelFitResult.score] descending (best fit first).
  List<ModelDiscoveryResult> _withFit(
    HardwareInfo hardware,
    List<HuggingFaceModelResult> results,
  ) {
    final withFit = [
      for (final model in results)
        ModelDiscoveryResult(
          model: model,
          fit: FitScorer.score(
            hardware: hardware,
            paramsBillions: model.paramsBillions,
            quant: model.quant,
          ),
          downloadStatus: downloadTracker.statusFor(model.repoId, model.quant),
        ),
    ];
    withFit.sort((a, b) => b.fit.score.compareTo(a.fit.score));
    return withFit;
  }

  /// Determines which Ollama [ServiceCard] (if any) a [download] should
  /// target, based on [ollamaCards]:
  /// - No Ollama cards → [OllamaCardResolution.none] (download unavailable).
  /// - A Default-marked Ollama card, or exactly one Ollama card → that card.
  /// - Multiple Ollama cards with none Default → [OllamaCardResolution.ambiguous],
  ///   carrying the candidates so the UI can prompt the user to choose.
  OllamaCardResolution resolveOllamaCard() {
    final candidates = ollamaCards.where((c) => c.type == ServiceType.ollama).toList();
    if (candidates.isEmpty) return const OllamaCardResolution.none();

    for (final card in candidates) {
      if (card.isDefault) return OllamaCardResolution.resolved(card);
    }

    if (candidates.length == 1) return OllamaCardResolution.resolved(candidates.single);

    return OllamaCardResolution.ambiguous(candidates);
  }

  /// `true` if [download] can proceed without the UI prompting for a card
  /// first — i.e. [resolveOllamaCard] returns a resolved card.
  bool get hasResolvableOllamaCard => resolveOllamaCard() is OllamaCardResolutionResolved;

  /// Pulls [result]'s (repoId, quant) into the target Ollama install,
  /// updating [result]'s [ModelDiscoveryResult.downloadStatus] as the pull
  /// progresses.
  ///
  /// [card] lets the UI pass an explicit choice (e.g. after the user picks
  /// from an ambiguous list via [resolveOllamaCard]). If omitted, the card is
  /// resolved automatically via [resolveOllamaCard]; if that resolution is
  /// not a single card (none configured, or ambiguous), [result]'s status is
  /// set to [DownloadStatus.failed] describing why.
  Future<void> download(ModelDiscoveryResult result, {ServiceCard? card}) async {
    final target = card ?? _resolveCardOrNull();
    if (target == null) {
      final resolution = resolveOllamaCard();
      final message = switch (resolution) {
        OllamaCardResolutionNone() =>
          'No Ollama service card is configured. Add one in Settings to enable downloads.',
        OllamaCardResolutionAmbiguous() =>
          'Multiple Ollama service cards are configured. Choose one to download into.',
        OllamaCardResolutionResolved() => '', // unreachable: _resolveCardOrNull would be non-null
      };
      _setStatus(result, DownloadStatus.failed(message), targetCard: target);
      return;
    }

    final health = await healthCheckRepository.check(target);
    if (health == HealthStatus.offline) {
      final baseUrl = target.fields['baseUrl'];
      _setStatus(
        result,
        DownloadStatus.failed("Ollama isn't reachable at $baseUrl. Make sure it's running."),
        targetCard: target,
      );
      return;
    }

    _setStatus(result, const DownloadStatus.downloading(OllamaPullProgress(status: 'starting')),
        targetCard: target);

    final ollamaDatasource = ollamaDatasourceFor(target);
    final pullName = 'hf.co/${result.model.repoId}:${result.model.quant}';

    try {
      await for (final progress in ollamaDatasource.pullModel(name: pullName)) {
        _setStatus(result, DownloadStatus.downloading(progress), targetCard: target);
      }
      _setStatus(result, const DownloadStatus.added(), targetCard: target);
    } catch (e) {
      final message = _describeDownloadError(e, target);
      _setStatus(result, DownloadStatus.failed(message), targetCard: target);
    }
  }

  /// Maps an error thrown while pulling into a user-facing message naming
  /// [target]'s `baseUrl` where relevant. See [download] doc for the exact
  /// shapes.
  String _describeDownloadError(Object e, ServiceCard target) {
    if (e is ChatRequestException) return e.message;
    if (e is DioException) {
      if (e.response == null) {
        final baseUrl = target.fields['baseUrl'];
        return 'Ollama became unreachable at $baseUrl (${e.message}). Make sure it\'s running.';
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  ServiceCard? _resolveCardOrNull() {
    final resolution = resolveOllamaCard();
    return resolution is OllamaCardResolutionResolved ? resolution.card : null;
  }

  /// Replaces [target]'s entry in `state.data!.results` with a copy carrying
  /// [status], matched by (repoId, quant). Uses [update] (not [execute]) so
  /// the rest of [ModelDiscoveryState] — hardware, other results, search
  /// results — is preserved.
  ///
  /// Also mirrors [status] into [downloadTracker] so it survives this
  /// controller (and the dialog it backs) being disposed.
  void _setStatus(ModelDiscoveryResult target, DownloadStatus status, {ServiceCard? targetCard}) {
    downloadTracker.track(HuggingFaceDownload(
      repoId: target.model.repoId,
      quant: target.model.quant,
      displayName: target.model.displayName,
      status: status,
      serviceCardId: targetCard?.id,
    ));

    update((current) {
      if (current is! AsyncData<ModelDiscoveryState>) return current;
      final state = current.data;
      final results = [
        for (final result in state.results)
          if (result.model.repoId == target.model.repoId && result.model.quant == target.model.quant)
            result.copyWith(downloadStatus: status)
          else
            result,
      ];
      return AsyncData(state.copyWith(results: results));
    });
  }
}
