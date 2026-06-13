import 'download_status.dart';

/// A Hugging Face download tracked by [HuggingFaceDownloadTracker], keyed by
/// (repoId, quant) so it survives the "Search Hugging Face" dialog closing.
class HuggingFaceDownload {
  final String repoId;
  final String quant;
  final String displayName;
  final DownloadStatus status;
  final String? serviceCardId;

  const HuggingFaceDownload({
    required this.repoId,
    required this.quant,
    required this.displayName,
    required this.status,
    this.serviceCardId,
  });

  String get key => '$repoId:$quant';

  HuggingFaceDownload copyWith({DownloadStatus? status, String? serviceCardId}) => HuggingFaceDownload(
        repoId: repoId,
        quant: quant,
        displayName: displayName,
        status: status ?? this.status,
        serviceCardId: serviceCardId ?? this.serviceCardId,
      );
}
