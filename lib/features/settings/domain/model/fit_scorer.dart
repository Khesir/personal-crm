import 'hardware_info.dart';
import 'model_fit_result.dart';

/// Approximate bytes-per-parameter for common GGUF quantization schemes,
/// used by [estimateVramMb].
///
/// These are rough averages (actual bits-per-weight vary slightly across
/// tensors within a quant scheme) — good enough for an order-of-magnitude
/// VRAM estimate, not an exact figure.
const Map<String, double> _bytesPerParam = {
  'Q2_K': 0.35,
  'Q3_K_S': 0.40,
  'Q3_K_M': 0.42,
  'Q3_K_L': 0.45,
  'Q4_0': 0.50,
  'Q4_K_S': 0.50,
  'Q4_K_M': 0.55,
  'Q5_K_S': 0.60,
  'Q5_K_M': 0.65,
  'Q6_K': 0.75,
  'Q8_0': 1.00,
  'F16': 2.00,
  'BF16': 2.00,
  'F32': 4.00,
};

/// Fallback bytes-per-param for quant strings not in [_bytesPerParam]
/// (e.g. unrecognized or future quant names). Equal to the Q4_K_M entry
/// above — Q4_K_M is the most common "balanced" GGUF quantization, so
/// unknown quants are treated as roughly equivalent to it.
const double _fallbackBytesPerParam = 0.55;

/// Fixed overhead added on top of raw weight size to account for the KV
/// cache, activation buffers, and runtime overhead at a typical context
/// length. This is a flat estimate, not scaled by context length — good
/// enough for a rough VRAM estimate.
const int ctxOverheadMb = 512;

/// Estimates the VRAM (or RAM, for CPU inference) required to load a model
/// of [paramsBillions] billion parameters quantized as [quant], in MB.
///
/// `paramsBillions * bytesPerParam(quant)` gives the weights size in
/// gigabytes (since 1 billion params * N bytes/param = N gigabytes); the
/// `* 1024` converts that to MB, and [ctxOverheadMb] is added as a flat
/// allowance for the KV cache and runtime overhead.
///
/// Unknown/unrecognized [quant] strings fall back to a Q4_K_M-equivalent
/// bytes-per-param (see [_fallbackBytesPerParam]) — a reasonable default
/// since Q4_K_M is the most common "balanced" GGUF quantization.
int estimateVramMb(double paramsBillions, String quant) {
  final bytesPerParam = _bytesPerParam[quant] ?? _fallbackBytesPerParam;
  final weightsMb = paramsBillions * bytesPerParam * 1024;
  return (weightsMb + ctxOverheadMb).round();
}

/// Pure, side-effect-free scoring of how well a (model, quantization) pair
/// fits the locally detected hardware.
///
/// [speedTokensPerSec] and [score] in the returned [ModelFitResult] are
/// **heuristic estimates** — see [ModelFitResult]'s class doc. They are
/// derived only from [fit]/[mode]/[paramsBillions]/[hardware.cpuCores], not
/// from any actual inference run.
abstract final class FitScorer {
  /// Scores a (model, quantization) pair described by [paramsBillions] and
  /// [quant] against [hardware].
  static ModelFitResult score({
    required HardwareInfo hardware,
    required double paramsBillions,
    required String quant,
  }) {
    final vramEstimateMb = estimateVramMb(paramsBillions, quant);

    final (fit, mode) = _classify(hardware: hardware, vramEstimateMb: vramEstimateMb);

    final speed = _estimateSpeed(
      fit: fit,
      mode: mode,
      paramsBillions: paramsBillions,
      cpuCores: hardware.cpuCores,
    );
    final score = _estimateScore(
      fit: fit,
      paramsBillions: paramsBillions,
      cpuCores: hardware.cpuCores,
    );

    return ModelFitResult(
      vramEstimateMb: vramEstimateMb,
      fit: fit,
      mode: mode,
      speedTokensPerSec: speed,
      score: score,
    );
  }

  /// Classifies [vramEstimateMb] against [hardware]'s VRAM/RAM into a
  /// (Fit, FitMode) pair.
  ///
  /// On hardware with no dedicated GPU, `vramAvailableMb` is 0 (or near
  /// it), so `vramEstimateMb <= vramAvailableMb * 0.9/1.1` can only hold if
  /// `vramEstimateMb` is also ~0 — which never happens for a real model.
  /// The GPU branches therefore naturally fall through to the CPU/RAM
  /// branches below.
  static (Fit, FitMode) _classify({
    required HardwareInfo hardware,
    required int vramEstimateMb,
  }) {
    final vramAvailable = hardware.vramAvailableMb;

    if (vramEstimateMb <= vramAvailable * 0.9) {
      // Fits comfortably with headroom for the KV cache and other GPU
      // allocations.
      return (Fit.perfect, FitMode.gpu);
    }

    if (vramEstimateMb <= vramAvailable * 1.1) {
      // Fits VRAM tightly (or very slightly overflows it). If it still
      // fits within the available VRAM outright, treat it as a full GPU
      // load; if it slightly exceeds available VRAM (within the 10%
      // tolerance band), assume a small partial CPU offload.
      final mode = vramEstimateMb <= vramAvailable ? FitMode.gpu : FitMode.partial;
      return (Fit.good, mode);
    }

    if (vramEstimateMb <= hardware.ramAvailableMb) {
      // Doesn't fit VRAM (or there's no dedicated GPU at all), but fits in
      // system RAM for CPU-only inference.
      return (Fit.cpuOnly, FitMode.cpu);
    }

    // Doesn't fit even system RAM — this model would not run.
    return (Fit.tooBig, FitMode.none);
  }

  /// Heuristic, non-measured "tokens/sec" estimate.
  ///
  /// Each [Fit] tier has a base throughput (GPU-resident tiers are much
  /// faster than CPU-bound ones; [Fit.tooBig] is always 0 since the model
  /// can't run at all). Within a tier, throughput scales down with
  /// [paramsBillions] (bigger models are slower) and, for CPU-bound modes,
  /// scales up with [cpuCores] (more cores -> faster CPU inference).
  static double _estimateSpeed({
    required Fit fit,
    required FitMode mode,
    required double paramsBillions,
    required int cpuCores,
  }) {
    if (fit == Fit.tooBig) return 0.0;

    final params = paramsBillions <= 0 ? 1.0 : paramsBillions;

    final double base = switch (fit) {
      Fit.perfect => 60.0,
      Fit.good => 40.0,
      Fit.cpuOnly => 8.0,
      Fit.tooBig => 0.0,
    };

    // Larger models run slower: divide by a sub-linear function of params
    // so the effect is meaningful but doesn't blow up for tiny models.
    var speed = base / (1 + (params - 1) * 0.08).clamp(0.2, double.infinity);

    // CPU-bound modes benefit from extra cores; GPU-resident modes don't.
    if (mode == FitMode.cpu || mode == FitMode.partial) {
      speed += cpuCores * 0.15;
    }

    return double.parse(speed.clamp(0.0, 1000.0).toStringAsFixed(2));
  }

  /// Heuristic, non-measured "fit score" from 0-100.
  ///
  /// Each [Fit] tier maps to a non-overlapping score band (so the tier
  /// ordering `perfect > good > cpuOnly > tooBig` always holds regardless
  /// of [paramsBillions]/[cpuCores]):
  /// - [Fit.perfect]: 80-100
  /// - [Fit.good]: 55-80
  /// - [Fit.cpuOnly]: 10-55
  /// - [Fit.tooBig]: 0-5 (near 0, since the model won't run)
  ///
  /// Within a band, smaller [paramsBillions] and more [cpuCores] push the
  /// score toward the top of the band.
  static double _estimateScore({
    required Fit fit,
    required double paramsBillions,
    required int cpuCores,
  }) {
    if (fit == Fit.tooBig) {
      // Tiny, near-zero score: the model won't run on this hardware at
      // all. A small positive value (rather than a flat 0) still lets
      // smaller/closer-to-fitting models rank marginally above wildly
      // oversized ones.
      final bonus = (10 / paramsBillions).clamp(0.0, 4.0);
      return double.parse(bonus.toStringAsFixed(2));
    }

    final params = paramsBillions <= 0 ? 1.0 : paramsBillions;

    final (double bandMin, double bandMax) = switch (fit) {
      Fit.perfect => (80.0, 100.0),
      Fit.good => (55.0, 80.0),
      Fit.cpuOnly => (10.0, 55.0),
      Fit.tooBig => (0.0, 5.0),
    };

    // Smaller models score closer to the top of the band; larger models
    // (within the same tier) score closer to the bottom.
    final paramsFactor = (1 / (1 + (params - 1) * 0.05)).clamp(0.0, 1.0);

    // More CPU cores nudge the score up slightly (helps CPU-bound tiers
    // the most, but applies generally since more cores never hurts).
    final coresFactor = (cpuCores / 64).clamp(0.0, 1.0);

    final fraction = (0.6 * paramsFactor + 0.4 * coresFactor).clamp(0.0, 1.0);
    final value = bandMin + (bandMax - bandMin) * fraction;

    return double.parse(value.clamp(bandMin, bandMax).toStringAsFixed(2));
  }
}
