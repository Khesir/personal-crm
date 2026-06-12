/// How well a (model, quantization) pair fits the locally detected hardware,
/// from [FitScorer.score] — see `domain/model/fit_scorer.dart`.
///
/// Ordered from best to worst; [index] is used by [FitScorer] to derive
/// monotonic SPEED/SCORE heuristics.
enum Fit {
  /// Estimated VRAM usage fits comfortably within available VRAM (with
  /// headroom for the KV cache and other allocations).
  perfect,

  /// Estimated VRAM usage fits available VRAM, but tightly — little to no
  /// headroom left.
  good,

  /// Doesn't fit VRAM (or no dedicated GPU was detected), but fits in
  /// available system RAM for CPU inference.
  cpuOnly,

  /// Doesn't fit even available system RAM — this model would not run.
  tooBig,
}

/// Where inference would run for a (model, quantization) pair, from
/// [FitScorer.score].
enum FitMode {
  /// Runs entirely on the GPU.
  gpu,

  /// Split across GPU and CPU/RAM.
  partial,

  /// Runs entirely on the CPU, using system RAM.
  cpu,

  /// Won't run on this hardware at all.
  none,
}

/// Result of comparing a (model, quantization) pair against the locally
/// detected [HardwareInfo] — see `domain/model/fit_scorer.dart`.
///
/// [speedTokensPerSec] and [score] are **heuristic estimates** derived from
/// [fit]/[mode]/the model's parameter count/the machine's CPU core count.
/// They are NOT measured benchmarks — no model is actually run to produce
/// these numbers. They exist purely to give the user a rough, relative sense
/// of "this one will probably run well, this one probably won't".
class ModelFitResult {
  /// Estimated VRAM required to load the model and run inference, in MB —
  /// see `estimateVramMb`.
  final int vramEstimateMb;

  /// How well this (model, quantization) pair fits the detected hardware.
  final Fit fit;

  /// Where inference would run for this (model, quantization) pair.
  final FitMode mode;

  /// Heuristic, non-measured estimate of inference throughput in
  /// tokens/sec. See class doc — this is NOT a benchmark.
  final double speedTokensPerSec;

  /// Heuristic, non-measured fit score from 0-100 (higher is better). See
  /// class doc — this is NOT a benchmark.
  final double score;

  const ModelFitResult({
    required this.vramEstimateMb,
    required this.fit,
    required this.mode,
    required this.speedTokensPerSec,
    required this.score,
  });
}
