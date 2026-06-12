/// A single (model, quantization) result from a Hugging Face Hub GGUF
/// search — see [HuggingFaceDatasource.searchModels].
class HuggingFaceModelResult {
  /// Hugging Face repo id, e.g. "TheBloke/Llama-2-7B-Chat-GGUF".
  final String repoId;

  /// Human-friendly name derived from [repoId] (the part after the last
  /// `/`).
  final String displayName;

  /// Parameter count in billions, e.g. 7.0 for "7B".
  final double paramsBillions;

  /// Quantization label, e.g. "Q4_K_M".
  final String quant;

  final int fileSizeBytes;

  /// Context length in tokens, or null if unknown.
  final int? contextLength;

  const HuggingFaceModelResult({
    required this.repoId,
    required this.displayName,
    required this.paramsBillions,
    required this.quant,
    required this.fileSizeBytes,
    this.contextLength,
  });
}
