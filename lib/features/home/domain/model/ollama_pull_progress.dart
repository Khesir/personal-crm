/// A single progress update from Ollama's `POST /api/pull` streaming
/// endpoint — see [OllamaDatasource.pullModel].
///
/// Most lines carry only [status] (e.g. "pulling manifest", "verifying
/// sha256 digest", "success"). While a layer is downloading, lines also
/// carry [totalBytes] and [completedBytes] for that layer.
class OllamaPullProgress {
  final String status;
  final int? totalBytes;
  final int? completedBytes;

  const OllamaPullProgress({
    required this.status,
    this.totalBytes,
    this.completedBytes,
  });

  factory OllamaPullProgress.fromJson(Map<String, dynamic> json) => OllamaPullProgress(
        status: json['status'] as String? ?? '',
        totalBytes: json['total'] as int?,
        completedBytes: json['completed'] as int?,
      );

  @override
  String toString() =>
      'OllamaPullProgress(status: $status, totalBytes: $totalBytes, completedBytes: $completedBytes)';
}
