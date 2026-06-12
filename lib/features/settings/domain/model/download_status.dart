import 'package:crm/features/home/domain/model/ollama_pull_progress.dart';

import 'service_card.dart';

/// Per-result download state for a [ModelDiscoveryResult], driven by
/// [OllamaDatasource.pullModel] — see `ModelDiscoveryController.download`.
sealed class DownloadStatus {
  const DownloadStatus();

  /// No download has been started for this result yet.
  const factory DownloadStatus.idle() = DownloadStatusIdle;

  /// A `/api/pull` request is in flight; [progress] is the latest update.
  const factory DownloadStatus.downloading(OllamaPullProgress progress) = DownloadStatusDownloading;

  /// The pull completed successfully (`{"status": "success"}`).
  const factory DownloadStatus.added() = DownloadStatusAdded;

  /// The pull failed; [message] is a user-facing description of why.
  const factory DownloadStatus.failed(String message) = DownloadStatusFailed;
}

class DownloadStatusIdle extends DownloadStatus {
  const DownloadStatusIdle();
}

class DownloadStatusDownloading extends DownloadStatus {
  final OllamaPullProgress progress;
  const DownloadStatusDownloading(this.progress);
}

class DownloadStatusAdded extends DownloadStatus {
  const DownloadStatusAdded();
}

class DownloadStatusFailed extends DownloadStatus {
  final String message;
  const DownloadStatusFailed(this.message);
}

/// Result of resolving which [ServiceCard] a download should target — see
/// `ModelDiscoveryController.resolveOllamaCard`.
sealed class OllamaCardResolution {
  const OllamaCardResolution();

  /// No Ollama service card is configured — download is unavailable.
  const factory OllamaCardResolution.none() = OllamaCardResolutionNone;

  /// A single target card was resolved unambiguously (the Default-marked
  /// card, or the sole Ollama card).
  const factory OllamaCardResolution.resolved(ServiceCard card) = OllamaCardResolutionResolved;

  /// Multiple Ollama cards exist and none is marked Default — the UI must
  /// prompt the user to pick one from [candidates].
  const factory OllamaCardResolution.ambiguous(List<ServiceCard> candidates) =
      OllamaCardResolutionAmbiguous;
}

class OllamaCardResolutionNone extends OllamaCardResolution {
  const OllamaCardResolutionNone();
}

class OllamaCardResolutionResolved extends OllamaCardResolution {
  final ServiceCard card;
  const OllamaCardResolutionResolved(this.card);
}

class OllamaCardResolutionAmbiguous extends OllamaCardResolution {
  final List<ServiceCard> candidates;
  const OllamaCardResolutionAmbiguous(this.candidates);
}
