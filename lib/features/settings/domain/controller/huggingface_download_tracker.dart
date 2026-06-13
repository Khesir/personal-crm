import 'package:crm/core/state/state.dart';
import '../model/download_status.dart';
import '../model/huggingface_download.dart';

/// App-lifetime tracker for Hugging Face downloads started from the "Search
/// Hugging Face" dialog, keyed by (repoId, quant). In-memory only — does not
/// persist across app restarts.
///
/// [ModelDiscoveryController] reads [statusFor] when building results so a
/// freshly-opened dialog reflects an in-progress/completed/failed download
/// instead of resetting to idle, and writes via [track] as
/// `download()` progresses. The Local LLM Services section reads [stream] to
/// show in-progress and recently-finished downloads outside the dialog.
class HuggingFaceDownloadTracker extends StreamState<List<HuggingFaceDownload>> {
  HuggingFaceDownloadTracker() : super(const []);

  static final HuggingFaceDownloadTracker instance = HuggingFaceDownloadTracker();

  /// The tracked status for (repoId, quant), or [DownloadStatus.idle] if not
  /// tracked.
  DownloadStatus statusFor(String repoId, String quant) {
    final key = '$repoId:$quant';
    for (final download in state) {
      if (download.key == key) return download.status;
    }
    return const DownloadStatus.idle();
  }

  /// The tracked [HuggingFaceDownload] for (repoId, quant), or `null` if not
  /// tracked.
  HuggingFaceDownload? downloadFor(String repoId, String quant) {
    final key = '$repoId:$quant';
    for (final download in state) {
      if (download.key == key) return download;
    }
    return null;
  }

  /// Inserts [download], or replaces the existing entry with the same
  /// [HuggingFaceDownload.key].
  void track(HuggingFaceDownload download) {
    final next = [
      for (final existing in state)
        if (existing.key != download.key) existing,
      download,
    ];
    emit(next);
  }

  /// Removes the tracked entry for (repoId, quant), if any.
  void dismiss(String repoId, String quant) {
    final key = '$repoId:$quant';
    emit([for (final download in state) if (download.key != key) download]);
  }
}
