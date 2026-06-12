import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/settings/domain/model/fit_scorer.dart';
import 'package:crm/features/settings/domain/model/hardware_info.dart';
import 'package:crm/features/settings/domain/model/model_fit_result.dart';

// A high-end discrete GPU with plenty of headroom.
const _bigGpu = HardwareInfo(
  gpuName: 'NVIDIA GeForce RTX 4090',
  vramTotalMb: 24576,
  vramAvailableMb: 22528,
  cudaAvailable: true,
  ramTotalMb: 32000,
  ramAvailableMb: 16000,
  cpuCores: 16,
);

// A small/entry-level discrete GPU with tight VRAM headroom.
const _smallGpuTightFit = HardwareInfo(
  gpuName: 'NVIDIA GeForce GTX 1650',
  vramTotalMb: 4096,
  vramAvailableMb: 4500,
  cudaAvailable: true,
  ramTotalMb: 16000,
  ramAvailableMb: 12000,
  cpuCores: 8,
);

// A small/entry-level discrete GPU where the model slightly overflows VRAM
// (partial offload territory).
const _smallGpuPartialFit = HardwareInfo(
  gpuName: 'NVIDIA GeForce GTX 1650',
  vramTotalMb: 4096,
  vramAvailableMb: 4400,
  cudaAvailable: true,
  ramTotalMb: 16000,
  ramAvailableMb: 12000,
  cpuCores: 8,
);

// No dedicated GPU detected (issue 003's fallback): gpuName null, 0 VRAM,
// but a reasonable amount of system RAM.
const _noGpu = HardwareInfo(
  gpuName: null,
  vramTotalMb: 0,
  vramAvailableMb: 0,
  cudaAvailable: false,
  ramTotalMb: 16000,
  ramAvailableMb: 16000,
  cpuCores: 8,
);

// No dedicated GPU and not much RAM either — even a mid-size model won't
// fit.
const _lowEndNoGpu = HardwareInfo(
  gpuName: null,
  vramTotalMb: 0,
  vramAvailableMb: 0,
  cudaAvailable: false,
  ramTotalMb: 8000,
  ramAvailableMb: 4000,
  cpuCores: 4,
);

void main() {
  group('estimateVramMb', () {
    test('7B Q4_K_M', () {
      // 7 * 0.55 * 1024 + 512 = 3942.4 + 512 = 4454.4 -> rounds to 4454.
      expect(estimateVramMb(7.0, 'Q4_K_M'), 4454);
    });

    test('13B Q5_K_M', () {
      // 13 * 0.65 * 1024 + 512 = 8652.8 + 512 = 9164.8 -> rounds to 9165.
      expect(estimateVramMb(13.0, 'Q5_K_M'), 9165);
    });

    test('70B Q8_0', () {
      // 70 * 1.00 * 1024 + 512 = 71680 + 512 = 72192.
      expect(estimateVramMb(70.0, 'Q8_0'), 72192);
    });

    test('unknown quant falls back to Q4_K_M-equivalent bytes-per-param', () {
      expect(estimateVramMb(7.0, 'SOME_FUTURE_QUANT'), estimateVramMb(7.0, 'Q4_K_M'));
    });

    test('F32 is the most expensive of the known quants', () {
      final f32 = estimateVramMb(7.0, 'F32');
      final f16 = estimateVramMb(7.0, 'F16');
      final q2k = estimateVramMb(7.0, 'Q2_K');
      expect(f32, greaterThan(f16));
      expect(f16, greaterThan(q2k));
    });
  });

  group('FitScorer.score', () {
    test('GPU with ample VRAM -> perfect/gpu', () {
      final result = FitScorer.score(hardware: _bigGpu, paramsBillions: 7.0, quant: 'Q4_K_M');

      expect(result.vramEstimateMb, 4454);
      expect(result.fit, Fit.perfect);
      expect(result.mode, FitMode.gpu);
    });

    test('GPU with tight VRAM (fits, but not with 10% headroom) -> good/gpu', () {
      final result =
          FitScorer.score(hardware: _smallGpuTightFit, paramsBillions: 7.0, quant: 'Q4_K_M');

      expect(result.vramEstimateMb, 4454);
      expect(result.fit, Fit.good);
      expect(result.mode, FitMode.gpu);
    });

    test('GPU with slightly-too-small VRAM (within 10% tolerance) -> good/partial', () {
      final result =
          FitScorer.score(hardware: _smallGpuPartialFit, paramsBillions: 7.0, quant: 'Q4_K_M');

      expect(result.vramEstimateMb, 4454);
      expect(result.fit, Fit.good);
      expect(result.mode, FitMode.partial);
    });

    test('no GPU but enough RAM -> cpuOnly/cpu', () {
      final result = FitScorer.score(hardware: _noGpu, paramsBillions: 7.0, quant: 'Q4_K_M');

      expect(result.vramEstimateMb, 4454);
      expect(result.fit, Fit.cpuOnly);
      expect(result.mode, FitMode.cpu);
    });

    test('too big for available RAM -> tooBig/none', () {
      final result = FitScorer.score(hardware: _bigGpu, paramsBillions: 70.0, quant: 'Q8_0');

      expect(result.vramEstimateMb, 72192);
      expect(result.fit, Fit.tooBig);
      expect(result.mode, FitMode.none);
    });

    test('no dGPU and not enough RAM -> tooBig/none, no crash', () {
      final result = FitScorer.score(hardware: _lowEndNoGpu, paramsBillions: 7.0, quant: 'Q4_K_M');

      expect(result.vramEstimateMb, 4454);
      expect(result.fit, Fit.tooBig);
      expect(result.mode, FitMode.none);
    });

    test('no dGPU hardware never produces a GPU-mode result', () {
      for (final params in [1.0, 7.0, 13.0, 34.0, 70.0]) {
        final result = FitScorer.score(hardware: _noGpu, paramsBillions: params, quant: 'Q4_K_M');
        expect(result.mode, isNot(FitMode.gpu));
        expect(result.mode, isNot(FitMode.partial));
      }
    });

    test('speedTokensPerSec and score are non-negative for every fit tier', () {
      final cases = [
        FitScorer.score(hardware: _bigGpu, paramsBillions: 7.0, quant: 'Q4_K_M'), // perfect
        FitScorer.score(
            hardware: _smallGpuTightFit, paramsBillions: 7.0, quant: 'Q4_K_M'), // good
        FitScorer.score(hardware: _noGpu, paramsBillions: 7.0, quant: 'Q4_K_M'), // cpuOnly
        FitScorer.score(hardware: _bigGpu, paramsBillions: 70.0, quant: 'Q8_0'), // tooBig
      ];

      for (final result in cases) {
        expect(result.speedTokensPerSec, greaterThanOrEqualTo(0));
        expect(result.score, greaterThanOrEqualTo(0));
        expect(result.score, lessThanOrEqualTo(100));
      }
    });

    test('score and speed are ordered consistently with fit: perfect > good > cpuOnly > tooBig',
        () {
      final perfect = FitScorer.score(hardware: _bigGpu, paramsBillions: 7.0, quant: 'Q4_K_M');
      final good =
          FitScorer.score(hardware: _smallGpuTightFit, paramsBillions: 7.0, quant: 'Q4_K_M');
      final cpuOnly = FitScorer.score(hardware: _noGpu, paramsBillions: 7.0, quant: 'Q4_K_M');
      final tooBig = FitScorer.score(hardware: _bigGpu, paramsBillions: 70.0, quant: 'Q8_0');

      expect(perfect.fit, Fit.perfect);
      expect(good.fit, Fit.good);
      expect(cpuOnly.fit, Fit.cpuOnly);
      expect(tooBig.fit, Fit.tooBig);

      expect(perfect.score, greaterThan(good.score));
      expect(good.score, greaterThan(cpuOnly.score));
      expect(cpuOnly.score, greaterThan(tooBig.score));

      expect(perfect.speedTokensPerSec, greaterThan(good.speedTokensPerSec));
      expect(good.speedTokensPerSec, greaterThan(cpuOnly.speedTokensPerSec));
      expect(cpuOnly.speedTokensPerSec, greaterThan(tooBig.speedTokensPerSec));
    });

    test('within the same fit tier, smaller paramsBillions -> higher speed and score', () {
      final small = FitScorer.score(hardware: _bigGpu, paramsBillions: 1.0, quant: 'Q4_K_M');
      final large = FitScorer.score(hardware: _bigGpu, paramsBillions: 13.0, quant: 'Q4_K_M');

      expect(small.fit, Fit.perfect);
      expect(large.fit, Fit.perfect);
      expect(small.speedTokensPerSec, greaterThan(large.speedTokensPerSec));
      expect(small.score, greaterThan(large.score));
    });

    test('within cpu-bound tiers, more cpuCores -> higher speed', () {
      const moreCores = HardwareInfo(
        gpuName: null,
        vramTotalMb: 0,
        vramAvailableMb: 0,
        cudaAvailable: false,
        ramTotalMb: 32000,
        ramAvailableMb: 16000,
        cpuCores: 32,
      );
      const fewerCores = HardwareInfo(
        gpuName: null,
        vramTotalMb: 0,
        vramAvailableMb: 0,
        cudaAvailable: false,
        ramTotalMb: 32000,
        ramAvailableMb: 16000,
        cpuCores: 4,
      );

      final moreCoresResult =
          FitScorer.score(hardware: moreCores, paramsBillions: 7.0, quant: 'Q4_K_M');
      final fewerCoresResult =
          FitScorer.score(hardware: fewerCores, paramsBillions: 7.0, quant: 'Q4_K_M');

      expect(moreCoresResult.fit, Fit.cpuOnly);
      expect(fewerCoresResult.fit, Fit.cpuOnly);
      expect(moreCoresResult.speedTokensPerSec, greaterThan(fewerCoresResult.speedTokensPerSec));
    });
  });
}
