import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/settings/data/repository/hardware_info_repository_impl.dart';
import 'package:crm/features/settings/domain/repository/process_runner.dart';

/// Fake [ProcessRunner] returning canned [ProcessResult]s keyed by
/// executable name. If a [throwing] set contains the executable, [run]
/// throws a [ProcessException] instead (simulating "not found on PATH").
class FakeProcessRunner implements ProcessRunner {
  final Map<String, ProcessResult> resultsByExecutable;
  final Set<String> throwing;

  FakeProcessRunner({
    this.resultsByExecutable = const {},
    this.throwing = const {},
  });

  @override
  Future<ProcessResult> run(String executable, List<String> args) async {
    if (throwing.contains(executable)) {
      throw ProcessException(executable, args, 'not found');
    }
    final result = resultsByExecutable[executable];
    if (result == null) {
      return ProcessResult(0, 1, '', 'no canned result');
    }
    return result;
  }
}

ProcessResult _ok(String stdout) => ProcessResult(0, 0, stdout, '');
ProcessResult _fail() => ProcessResult(0, 1, '', 'error');

const _ramJson = '{"TotalVisibleMemorySize":33415288,"FreePhysicalMemory":12345678}';

void main() {
  group('HardwareInfoRepositoryImpl', () {
    test('parses nvidia-smi CSV output into GPU/VRAM/CUDA info', () async {
      final runner = FakeProcessRunner(resultsByExecutable: {
        'nvidia-smi': _ok('NVIDIA GeForce RTX 4090, 24576, 2048\n'),
        'powershell': _ok(_ramJson),
      });

      final info = await HardwareInfoRepositoryImpl(runner).detect();

      expect(info.gpuName, 'NVIDIA GeForce RTX 4090');
      expect(info.vramTotalMb, 24576);
      expect(info.vramAvailableMb, 24576 - 2048);
      expect(info.cudaAvailable, isTrue);
      expect(info.ramTotalMb, 33415288 ~/ 1024);
      expect(info.ramAvailableMb, 12345678 ~/ 1024);
      expect(info.cpuCores, Platform.numberOfProcessors);
    });

    test('falls back to "no dedicated GPU" when nvidia-smi throws (not on PATH)', () async {
      final runner = FakeProcessRunner(
        resultsByExecutable: {'powershell': _ok(_ramJson)},
        throwing: {'nvidia-smi'},
      );

      final info = await HardwareInfoRepositoryImpl(runner).detect();

      expect(info.gpuName, isNull);
      expect(info.vramTotalMb, 0);
      expect(info.vramAvailableMb, 0);
      expect(info.cudaAvailable, isFalse);
      // RAM/CPU are still populated.
      expect(info.ramTotalMb, 33415288 ~/ 1024);
      expect(info.ramAvailableMb, 12345678 ~/ 1024);
      expect(info.cpuCores, Platform.numberOfProcessors);
    });

    test('falls back to "no dedicated GPU" when nvidia-smi exits non-zero', () async {
      final runner = FakeProcessRunner(resultsByExecutable: {
        'nvidia-smi': _fail(),
        'powershell': _ok(_ramJson),
      });

      final info = await HardwareInfoRepositoryImpl(runner).detect();

      expect(info.gpuName, isNull);
      expect(info.vramTotalMb, 0);
      expect(info.vramAvailableMb, 0);
      expect(info.cudaAvailable, isFalse);
    });

    test('falls back to RAM 0/0 when PowerShell returns malformed JSON, without throwing', () async {
      final runner = FakeProcessRunner(resultsByExecutable: {
        'nvidia-smi': _ok('NVIDIA GeForce RTX 4090, 24576, 2048\n'),
        'powershell': _ok('not json'),
      });

      final info = await HardwareInfoRepositoryImpl(runner).detect();

      expect(info.ramTotalMb, 0);
      expect(info.ramAvailableMb, 0);
      // GPU detection is unaffected.
      expect(info.gpuName, 'NVIDIA GeForce RTX 4090');
    });

    test('falls back to RAM 0/0 when PowerShell process throws', () async {
      final runner = FakeProcessRunner(
        resultsByExecutable: {'nvidia-smi': _ok('NVIDIA GeForce RTX 4090, 24576, 2048\n')},
        throwing: {'powershell'},
      );

      final info = await HardwareInfoRepositoryImpl(runner).detect();

      expect(info.ramTotalMb, 0);
      expect(info.ramAvailableMb, 0);
    });

    test('cpuCores equals Platform.numberOfProcessors', () async {
      final runner = FakeProcessRunner(resultsByExecutable: {
        'nvidia-smi': _fail(),
        'powershell': _ok(_ramJson),
      });

      final info = await HardwareInfoRepositoryImpl(runner).detect();

      expect(info.cpuCores, Platform.numberOfProcessors);
    });
  });
}
