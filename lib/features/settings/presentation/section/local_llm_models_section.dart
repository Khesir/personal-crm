import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/controller/huggingface_download_tracker.dart';
import '../../domain/model/download_status.dart';
import '../../domain/model/huggingface_download.dart';
import '../widget/huggingface_download_status_widgets.dart';

/// Lists in-progress and recently-finished Hugging Face downloads (started
/// from the "Search Hugging Face" dialog) so they stay visible after that
/// dialog is closed — see [HuggingFaceDownloadTracker]. Renders nothing once
/// no downloads are tracked.
class LocalLlmModelsSection extends StatelessWidget {
  final String? filterServiceCardId;

  const LocalLlmModelsSection({super.key, this.filterServiceCardId});

  @override
  Widget build(BuildContext context) {
    final tracker = HuggingFaceDownloadTracker.instance;
    return StreamBuilder<List<HuggingFaceDownload>>(
      stream: tracker.stream,
      initialData: tracker.state,
      builder: (context, snapshot) {
        final downloads = (snapshot.data ?? const [])
            .where((d) => d.status is! DownloadStatusIdle)
            .where((d) => filterServiceCardId == null || d.serviceCardId == filterServiceCardId)
            .toList();
        if (downloads.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppStyling.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Models', style: AppStyling.label),
              const SizedBox(height: AppStyling.spaceSm),
              for (final download in downloads)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppStyling.spaceSm),
                  child: _DownloadRow(download: download),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DownloadRow extends StatelessWidget {
  final HuggingFaceDownload download;

  const _DownloadRow({required this.download});

  bool get _dismissible =>
      download.status is DownloadStatusAdded || download.status is DownloadStatusFailed;

  Widget _statusWidget() => switch (download.status) {
        DownloadStatusDownloading(progress: final progress) => DownloadProgressIndicator(progress: progress),
        DownloadStatusAdded() => const DownloadAddedBadge(),
        DownloadStatusFailed(message: final message) => DownloadErrorMessage(message: message),
        DownloadStatusIdle() => const SizedBox.shrink(),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppStyling.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(download.displayName, style: AppStyling.bodySm.copyWith(color: AppColors.textPrimary)),
                Text(
                  '${download.repoId}:${download.quant}',
                  style: AppStyling.monoSm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppStyling.spaceMd),
          Expanded(flex: 2, child: _statusWidget()),
          if (_dismissible) ...[
            const SizedBox(width: AppStyling.spaceSm),
            IconButton(
              onPressed: () =>
                  HuggingFaceDownloadTracker.instance.dismiss(download.repoId, download.quant),
              icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              tooltip: 'Dismiss',
            ),
          ],
        ],
      ),
    );
  }
}
