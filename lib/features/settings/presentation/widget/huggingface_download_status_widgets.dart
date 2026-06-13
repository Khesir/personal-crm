import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/home/domain/model/ollama_pull_progress.dart';

/// Inline progress bar + status text for an in-progress Hugging Face
/// download. Shared by the "Search Hugging Face" dialog and the Local LLM
/// downloads list in Settings > Services.
class DownloadProgressIndicator extends StatelessWidget {
  final OllamaPullProgress progress;

  const DownloadProgressIndicator({super.key, required this.progress});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final total = progress.totalBytes;
    final completed = progress.completedBytes;
    final hasRatio = total != null && total > 0 && completed != null;
    final value = hasRatio ? completed / total : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppStyling.radiusSm),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            backgroundColor: AppColors.surfaceRaised,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppStyling.spaceXs),
        Text(
          hasRatio
              ? '${progress.status} (${_formatBytes(completed)} / ${_formatBytes(total)})'
              : progress.status,
          style: AppStyling.monoSm.copyWith(color: AppColors.textMuted),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Checkmark + "Added" label for a completed Hugging Face download. Shared by
/// the "Search Hugging Face" dialog and the Local LLM downloads list in
/// Settings > Services.
class DownloadAddedBadge extends StatelessWidget {
  const DownloadAddedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(0x29),
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 12, color: AppColors.success),
          const SizedBox(width: AppStyling.spaceXs),
          Text('Added', style: AppStyling.monoSm.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}

/// Error message for a failed Hugging Face download. Shared by the "Search
/// Hugging Face" dialog and the Local LLM downloads list in Settings >
/// Services.
class DownloadErrorMessage extends StatelessWidget {
  final String message;

  const DownloadErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppStyling.monoSm.copyWith(color: AppColors.error),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
