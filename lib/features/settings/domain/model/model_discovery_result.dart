import 'download_status.dart';
import 'huggingface_model_result.dart';
import 'model_fit_result.dart';

/// A single Hugging Face search result paired with how well it fits the
/// locally detected hardware — see [ModelDiscoveryController].
class ModelDiscoveryResult {
  final HuggingFaceModelResult model;
  final ModelFitResult fit;
  final DownloadStatus downloadStatus;

  const ModelDiscoveryResult({
    required this.model,
    required this.fit,
    this.downloadStatus = const DownloadStatus.idle(),
  });

  ModelDiscoveryResult copyWith({
    HuggingFaceModelResult? model,
    ModelFitResult? fit,
    DownloadStatus? downloadStatus,
  }) {
    return ModelDiscoveryResult(
      model: model ?? this.model,
      fit: fit ?? this.fit,
      downloadStatus: downloadStatus ?? this.downloadStatus,
    );
  }
}
