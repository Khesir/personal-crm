import 'hardware_info.dart';
import 'model_discovery_result.dart';

/// State for [ModelDiscoveryController]: the detected local hardware plus
/// the current Hugging Face search results, each paired with a
/// [ModelDiscoveryResult.fit] computed against [hardware].
class ModelDiscoveryState {
  final HardwareInfo hardware;
  final List<ModelDiscoveryResult> results;

  const ModelDiscoveryState({required this.hardware, required this.results});

  ModelDiscoveryState copyWith({
    HardwareInfo? hardware,
    List<ModelDiscoveryResult>? results,
  }) =>
      ModelDiscoveryState(
        hardware: hardware ?? this.hardware,
        results: results ?? this.results,
      );
}
