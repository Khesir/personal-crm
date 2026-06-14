/// Parses parameter count and GGUF quantization label out of a model
/// name/tag/filename, e.g. `"llama-2-7b-chat.Q4_K_M.gguf"` or
/// `"qwen2.5-coder:7b-instruct-q4_K_M"`.
///
/// Shared between [HuggingFaceDatasource] (parsing Hugging Face repo ids and
/// filenames) and [ChatController] (parsing local model names/tags for
/// [ModelFitResult] computation) — do not duplicate these regexes.
abstract final class ModelNameParser {
  static final _paramsRegex = RegExp(r'(\d+(?:\.\d+)?)[Bb]');
  static final _quantRegex = RegExp(
    r'(Q\d_K_[SML]|Q\d_K|Q\d_\d|BF16|F16|F32)',
    caseSensitive: false,
  );

  /// Parses the parameter count in billions from [text], e.g. `"7B"` -> 7.0.
  /// For MoE-style names like `"2x7B"`, the last `B`/`b`-suffixed number is
  /// used. Returns null if [text] contains no such number.
  static double? parseParamsBillions(String text) {
    final matches = _paramsRegex.allMatches(text).toList();
    if (matches.isEmpty) return null;
    return double.tryParse(matches.last.group(1)!);
  }

  /// Parses a GGUF quantization label from [text] (e.g. `"Q4_K_M"`,
  /// `"F16"`), normalized to uppercase. Returns null if [text] contains no
  /// recognized quant label.
  static String? parseQuant(String text) {
    final match = _quantRegex.firstMatch(text);
    if (match == null) return null;
    return match.group(1)!.toUpperCase();
  }
}
