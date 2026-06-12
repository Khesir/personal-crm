/// Snapshot of the local machine's hardware, used to size local LLM models
/// against available VRAM/RAM and to surface CUDA availability.
class HardwareInfo {
  /// GPU name (e.g. "NVIDIA GeForce RTX 4090"), or null if no dedicated GPU
  /// was detected.
  final String? gpuName;

  final int vramTotalMb;
  final int vramAvailableMb;
  final bool cudaAvailable;

  final int ramTotalMb;
  final int ramAvailableMb;

  final int cpuCores;

  const HardwareInfo({
    required this.gpuName,
    required this.vramTotalMb,
    required this.vramAvailableMb,
    required this.cudaAvailable,
    required this.ramTotalMb,
    required this.ramAvailableMb,
    required this.cpuCores,
  });
}
