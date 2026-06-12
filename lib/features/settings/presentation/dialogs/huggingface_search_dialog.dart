import 'package:flutter/material.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/home/domain/model/ollama_pull_progress.dart';
import '../../domain/controller/model_discovery_controller.dart';
import '../../domain/model/download_status.dart';
import '../../domain/model/hardware_info.dart';
import '../../domain/model/model_discovery_result.dart';
import '../../domain/model/model_discovery_state.dart';
import '../../domain/model/model_fit_result.dart';
import '../../domain/model/service_card.dart';

const _kDialogWidth = 820.0;

/// Dialog for "Search Hugging Face": shows the detected local hardware at
/// the top, a search field, and a results table of GGUF models with
/// hardware-fit (VRAM/SPEED/SCORE/FIT/MODE) info and a per-row Download
/// action that pulls the model into the configured Ollama install (see
/// [ModelDiscoveryController.download]).
class HuggingFaceSearchDialog extends StatefulWidget {
  final ModelDiscoveryController controller;

  const HuggingFaceSearchDialog({super.key, required this.controller});

  @override
  State<HuggingFaceSearchDialog> createState() => _HuggingFaceSearchDialogState();
}

class _HuggingFaceSearchDialogState extends State<HuggingFaceSearchDialog> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _submitSearch() {
    widget.controller.search(_searchCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SizedBox(
        width: _kDialogWidth,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.all(AppStyling.spaceXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Search Hugging Face', style: AppStyling.headingMd),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppStyling.spaceLg),
              AsyncStreamBuilder<ModelDiscoveryState>(
                state: widget.controller,
                loadingBuilder: (context) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppStyling.spaceXl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorBuilder: (context, message) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceXl),
                  child: Text(
                    'Failed to load: $message',
                    style: AppStyling.bodySm.copyWith(color: AppColors.error),
                  ),
                ),
                builder: (context, data) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HardwareBar(hardware: data.hardware),
                        const SizedBox(height: AppStyling.spaceLg),
                        _SearchField(
                          controller: _searchCtrl,
                          onSubmitted: (_) => _submitSearch(),
                        ),
                        const SizedBox(height: AppStyling.spaceLg),
                        const _ResultsHeader(),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: AppStyling.spaceXs),
                        Text(
                          'SPEED and SCORE are heuristic estimates based on your hardware, '
                          'not measured benchmarks.',
                          style: AppStyling.monoSm.copyWith(color: AppColors.textFaint),
                        ),
                        const SizedBox(height: AppStyling.spaceXs),
                        Expanded(
                          child: data.results.isEmpty
                              ? Center(
                                  child: Text(
                                    'No models found.',
                                    style: AppStyling.bodySm.copyWith(color: AppColors.textMuted),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: data.results.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1, color: AppColors.border),
                                  itemBuilder: (context, index) => _ResultRow(
                                    controller: widget.controller,
                                    result: data.results[index],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hardware-detection bar shown at the top of the dialog: GPU name, VRAM,
/// RAM, CPU core count, and CUDA availability.
class _HardwareBar extends StatelessWidget {
  final HardwareInfo hardware;

  const _HardwareBar({required this.hardware});

  String _formatMb(int mb) {
    if (mb <= 0) return '0 MB';
    if (mb >= 1024) {
      final gb = mb / 1024;
      return '${gb.toStringAsFixed(1)} GB';
    }
    return '$mb MB';
  }

  @override
  Widget build(BuildContext context) {
    final gpuLabel = hardware.gpuName ?? 'No dedicated GPU detected';
    final vramLabel = hardware.gpuName == null
        ? '—'
        : '${_formatMb(hardware.vramAvailableMb)} / ${_formatMb(hardware.vramTotalMb)}';
    final ramLabel = '${_formatMb(hardware.ramAvailableMb)} / ${_formatMb(hardware.ramTotalMb)}';

    return Container(
      padding: const EdgeInsets.all(AppStyling.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppStyling.spaceXl,
        runSpacing: AppStyling.spaceSm,
        children: [
          _HardwareStat(label: 'GPU', value: gpuLabel),
          _HardwareStat(label: 'VRAM', value: vramLabel),
          _HardwareStat(label: 'RAM', value: ramLabel),
          _HardwareStat(label: 'CPU', value: '${hardware.cpuCores} cores'),
          _HardwareStat(label: 'CUDA', value: hardware.cudaAvailable ? 'Available' : 'Not available'),
        ],
      ),
    );
  }
}

class _HardwareStat extends StatelessWidget {
  final String label;
  final String value;

  const _HardwareStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppStyling.label),
        const SizedBox(height: 2),
        Text(value, style: AppStyling.bodySm.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _SearchField({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppStyling.bodyLg,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Search Hugging Face for GGUF models…',
        hintStyle: AppStyling.bodySm.copyWith(color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppStyling.spaceMd),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}

/// Column headers for the results table: MODEL, PARAM, QUANT, CTX, VRAM,
/// SPEED, SCORE, FIT, MODE, DOWNLOAD.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceSm),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('MODEL', style: AppStyling.label)),
          Expanded(flex: 1, child: Text('PARAM', style: AppStyling.label)),
          Expanded(flex: 1, child: Text('QUANT', style: AppStyling.label)),
          Expanded(flex: 1, child: Text('CTX', style: AppStyling.label)),
          Expanded(flex: 1, child: Text('VRAM', style: AppStyling.label)),
          Expanded(flex: 1, child: Text('SPEED', style: AppStyling.label)),
          Expanded(flex: 1, child: Text('SCORE', style: AppStyling.label)),
          Expanded(flex: 1, child: Text('FIT', style: AppStyling.label)),
          Expanded(flex: 1, child: Text('MODE', style: AppStyling.label)),
          Expanded(flex: 2, child: Text('DOWNLOAD', style: AppStyling.label)),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final ModelDiscoveryController controller;
  final ModelDiscoveryResult result;

  const _ResultRow({required this.controller, required this.result});

  String _formatParams(double billions) {
    final isWhole = billions == billions.roundToDouble();
    return isWhole ? '${billions.toInt()}B' : '${billions}B';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '—';
    final gb = bytes / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(1)} GB';
  }

  String _formatVram(int mb) {
    if (mb <= 0) return '0 MB';
    if (mb >= 1024) {
      final gb = mb / 1024;
      return '${gb.toStringAsFixed(1)} GB';
    }
    return '$mb MB';
  }

  /// SPEED is a heuristic estimate (see [ModelFitResult] doc), not a
  /// measured benchmark — formatted with a leading "~" to make that clear
  /// at a glance.
  String _formatSpeed(double tokensPerSec) => '~${tokensPerSec.toStringAsFixed(0)} tok/s';

  /// SCORE is a heuristic 0-100 estimate (see [ModelFitResult] doc), not a
  /// measured benchmark.
  String _formatScore(double score) => score.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final model = result.model;
    final fit = result.fit;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyling.spaceSm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.displayName, style: AppStyling.bodySm.copyWith(color: AppColors.textPrimary)),
                Text(
                  '${model.repoId} • ${_formatSize(model.fileSizeBytes)}',
                  style: AppStyling.monoSm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text(_formatParams(model.paramsBillions), style: AppStyling.mono)),
          Expanded(flex: 1, child: Text(model.quant, style: AppStyling.mono)),
          Expanded(
            flex: 1,
            child: Text(
              model.contextLength != null ? '${model.contextLength}' : '—',
              style: AppStyling.mono,
            ),
          ),
          Expanded(flex: 1, child: Text(_formatVram(fit.vramEstimateMb), style: AppStyling.mono)),
          Expanded(
            flex: 1,
            child: Text(_formatSpeed(fit.speedTokensPerSec), style: AppStyling.monoSm),
          ),
          Expanded(
            flex: 1,
            child: Text(_formatScore(fit.score), style: AppStyling.mono),
          ),
          Expanded(flex: 1, child: _FitBadge(fit: fit.fit)),
          Expanded(flex: 1, child: Text(_modeLabel(fit.mode), style: AppStyling.monoSm)),
          Expanded(
            flex: 2,
            child: _DownloadCell(controller: controller, result: result),
          ),
        ],
      ),
    );
  }

  String _modeLabel(FitMode mode) => switch (mode) {
        FitMode.gpu => 'GPU',
        FitMode.partial => 'PARTIAL',
        FitMode.cpu => 'CPU',
        FitMode.none => 'NONE',
      };
}

/// The DOWNLOAD column for a single [_ResultRow]: a "Download" button (or a
/// disabled explanation if no Ollama card is configured), an inline progress
/// indicator while downloading, an "Added" badge on success, or an error +
/// retry button on failure.
class _DownloadCell extends StatelessWidget {
  final ModelDiscoveryController controller;
  final ModelDiscoveryResult result;

  const _DownloadCell({required this.controller, required this.result});

  Future<void> _startDownload(BuildContext context) async {
    final resolution = controller.resolveOllamaCard();
    switch (resolution) {
      case OllamaCardResolutionNone():
        // Button is disabled in this case — nothing to do.
        return;
      case OllamaCardResolutionResolved(card: final card):
        await controller.download(result, card: card);
      case OllamaCardResolutionAmbiguous(candidates: final candidates):
        final chosen = await showDialog<ServiceCard>(
          context: context,
          builder: (_) => _OllamaCardPickerDialog(candidates: candidates),
        );
        if (chosen == null) return;
        await controller.download(result, card: chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = result.downloadStatus;

    return switch (status) {
      DownloadStatusIdle() => _buildIdle(context),
      DownloadStatusDownloading(progress: final progress) => _ProgressIndicatorCell(progress: progress),
      DownloadStatusAdded() => const _AddedBadge(),
      DownloadStatusFailed(message: final message) => _FailedCell(
          message: message,
          onRetry: () => _startDownload(context),
        ),
    };
  }

  Widget _buildIdle(BuildContext context) {
    final resolution = controller.resolveOllamaCard();
    final isAvailable = resolution is! OllamaCardResolutionNone;

    final button = _DownloadButton(
      enabled: isAvailable,
      onPressed: isAvailable ? () => _startDownload(context) : null,
    );

    if (isAvailable) return button;

    return Tooltip(
      message: 'Configure an Ollama card to enable downloads',
      child: button,
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const _DownloadButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceXs,
        ),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceRaised : AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyling.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Download',
          style: AppStyling.monoSm.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textFaint,
          ),
        ),
      ),
    );
  }
}

/// Inline progress indicator for [DownloadStatus.downloading], shown in
/// place of the Download button while a pull is in flight.
class _ProgressIndicatorCell extends StatelessWidget {
  final OllamaPullProgress progress;

  const _ProgressIndicatorCell({required this.progress});

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

/// Shown for [DownloadStatus.added]: a checkmark + "Added" label, styled
/// similarly to [_FitBadge].
class _AddedBadge extends StatelessWidget {
  const _AddedBadge();

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

/// Shown for [DownloadStatus.failed]: the error message plus a "Download"
/// button to retry.
class _FailedCell extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailedCell({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: AppStyling.monoSm.copyWith(color: AppColors.error),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppStyling.spaceXs),
        _DownloadButton(enabled: true, onPressed: onRetry),
      ],
    );
  }
}

/// Picker shown when multiple Ollama cards are configured and none is
/// marked Default — lets the user choose which card to download into.
class _OllamaCardPickerDialog extends StatelessWidget {
  final List<ServiceCard> candidates;

  const _OllamaCardPickerDialog({required this.candidates});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppStyling.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Download into which Ollama card?', style: AppStyling.headingMd),
            const SizedBox(height: AppStyling.spaceMd),
            for (final card in candidates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(card.name, style: AppStyling.bodyLg),
                subtitle: card.fields['baseUrl'] != null
                    ? Text(
                        card.fields['baseUrl']!,
                        style: AppStyling.monoSm.copyWith(color: AppColors.textMuted),
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(card),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small color-coded badge summarizing [ModelFitResult.fit].
class _FitBadge extends StatelessWidget {
  final Fit fit;

  const _FitBadge({required this.fit});

  Color get _color => switch (fit) {
        Fit.perfect => AppColors.success,
        Fit.good => AppColors.info,
        Fit.cpuOnly => AppColors.warning,
        Fit.tooBig => AppColors.error,
      };

  String get _label => switch (fit) {
        Fit.perfect => 'PERFECT',
        Fit.good => 'GOOD',
        Fit.cpuOnly => 'CPU ONLY',
        Fit.tooBig => 'TOO BIG',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withAlpha(0x29),
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
      ),
      child: Text(
        _label,
        style: AppStyling.monoSm.copyWith(color: _color),
      ),
    );
  }
}
