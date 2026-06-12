import 'dart:convert';
import 'dart:io';

import '../../domain/model/hardware_info.dart';
import '../../domain/repository/hardware_info_repository.dart';
import '../../domain/repository/process_runner.dart';

/// Detects local GPU/VRAM/CUDA via `nvidia-smi`, RAM via a PowerShell
/// `Win32_OperatingSystem` query, and CPU core count via
/// [Platform.numberOfProcessors]. Targets Windows, the app's current desktop
/// platform.
///
/// Detection never throws — any failure (missing executable, non-zero exit,
/// unparseable output) falls back to "no dedicated GPU" / zeroed RAM rather
/// than surfacing an error to the user.
class HardwareInfoRepositoryImpl implements HardwareInfoRepository {
  final ProcessRunner _processRunner;

  HardwareInfoRepositoryImpl(this._processRunner);

  @override
  Future<HardwareInfo> detect() async {
    final gpu = await _detectGpu();
    final ram = await _detectRam();

    return HardwareInfo(
      gpuName: gpu.$1,
      vramTotalMb: gpu.$2,
      vramAvailableMb: gpu.$3,
      cudaAvailable: gpu.$4,
      ramTotalMb: ram.$1,
      ramAvailableMb: ram.$2,
      cpuCores: Platform.numberOfProcessors,
    );
  }

  /// Returns (gpuName, vramTotalMb, vramAvailableMb, cudaAvailable).
  Future<(String?, int, int, bool)> _detectGpu() async {
    const noGpu = (null, 0, 0, false);

    try {
      final result = await _processRunner.run('nvidia-smi', [
        '--query-gpu=name,memory.total,memory.used',
        '--format=csv,noheader,nounits',
      ]);
      if (result.exitCode != 0) return noGpu;

      final stdout = result.stdout.toString();
      final firstLine = stdout
          .split('\n')
          .map((l) => l.trim())
          .firstWhere((l) => l.isNotEmpty, orElse: () => '');
      if (firstLine.isEmpty) return noGpu;

      final parts = firstLine.split(',').map((p) => p.trim()).toList();
      if (parts.length < 3) return noGpu;

      final name = parts[0];
      final total = int.tryParse(parts[1]);
      final used = int.tryParse(parts[2]);
      if (name.isEmpty || total == null || used == null) return noGpu;

      return (name, total, total - used, true);
    } catch (_) {
      return noGpu;
    }
  }

  /// Returns (ramTotalMb, ramAvailableMb).
  Future<(int, int)> _detectRam() async {
    const noRam = (0, 0);

    try {
      final result = await _processRunner.run('powershell', [
        '-NoProfile',
        '-Command',
        'Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory | ConvertTo-Json',
      ]);
      if (result.exitCode != 0) return noRam;

      final decoded = jsonDecode(result.stdout.toString());
      if (decoded is! Map<String, dynamic>) return noRam;

      final totalKb = decoded['TotalVisibleMemorySize'];
      final freeKb = decoded['FreePhysicalMemory'];
      if (totalKb is! int || freeKb is! int) return noRam;

      return (totalKb ~/ 1024, freeKb ~/ 1024);
    } catch (_) {
      return noRam;
    }
  }
}
