import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/tool_call.dart';
import '../../domain/model/tool_execution_result.dart';
import '../helpers/tool_call_summary.dart';
import 'labeled_text_block.dart';
import 'step_card.dart';

/// Renders one [ToolCall] from an agent-mode assistant message as a
/// collapsible step card.
///
/// - If [resultText] is non-null, the call has been answered: shows the
///   tool's output/result text (and, for `write_file`/`edit_file`, the diff
///   that was applied, from [writePreview]).
/// - Otherwise the call is pending. For `write_file`/`edit_file`,
///   [writePreview] (derived from [call.arguments]) is shown along with
///   Approve/Reject buttons via [onApprove]/[onReject]. Other tools never
///   stay pending as a [ToolWriteProposal], so they render a generic
///   "pending" state.
class ToolCallStepCard extends StatelessWidget {
  final ToolCall call;
  final String? resultText;
  final ToolWritePreview? writePreview;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ToolCallStepCard({
    super.key,
    required this.call,
    this.resultText,
    this.writePreview,
    this.onApprove,
    this.onReject,
  });

  bool get _isPending => resultText == null;
  bool get _isWriteOrEdit => isWriteOrEditTool(call.name);
  bool get _isPendingApproval => _isWriteOrEdit || call.name == 'run_command';

  @override
  Widget build(BuildContext context) {
    return StepCard(
      header: _Header(call: call, pending: _isPending),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LabeledTextBlock(label: 'Arguments', content: _formatArguments(call.arguments)),
          if (writePreview != null) ...[
            const SizedBox(height: AppStyling.spaceMd),
            ..._buildPreview(writePreview!),
          ],
          if (resultText != null) ...[
            const SizedBox(height: AppStyling.spaceMd),
            LabeledTextBlock(label: 'Result', content: resultText!),
          ],
          if (_isPending && _isPendingApproval) ...[
            const SizedBox(height: AppStyling.spaceMd),
            _ApproveRejectRow(onApprove: onApprove, onReject: onReject),
          ] else if (_isPending) ...[
            const SizedBox(height: AppStyling.spaceMd),
            Text('Pending…', style: AppStyling.bodySm),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPreview(ToolWritePreview preview) {
    return switch (preview) {
      WriteFileCreation(content: final content) => [
          LabeledTextBlock(label: 'New file content', content: content),
        ],
      EditFileChange(oldText: final oldText, newText: final newText) => [
          LabeledTextBlock(
            label: 'Before',
            content: oldText,
            backgroundColor: AppColors.severityCritical.withValues(alpha: 0.08),
          ),
          const SizedBox(height: AppStyling.spaceSm),
          LabeledTextBlock(
            label: 'After',
            content: newText,
            backgroundColor: AppColors.success.withValues(alpha: 0.08),
          ),
        ],
      CommandExecution(command: final command, cwd: final cwd) => [
          LabeledTextBlock(label: 'Command', content: command),
          const SizedBox(height: AppStyling.spaceSm),
          LabeledTextBlock(label: 'Working directory', content: cwd),
        ],
    };
  }

  String _formatArguments(Map<String, dynamic> arguments) {
    if (arguments.isEmpty) return '(none)';
    return arguments.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}

class _Header extends StatelessWidget {
  final ToolCall call;
  final bool pending;

  const _Header({required this.call, required this.pending});

  @override
  Widget build(BuildContext context) {
    final summary = toolCallSummary(call);
    return Row(
      children: [
        Icon(
          pending ? Icons.hourglass_top : Icons.check_circle_outline,
          size: 16,
          color: pending ? AppColors.warning : AppColors.success,
        ),
        const SizedBox(width: AppStyling.spaceSm),
        Text(call.name, style: AppStyling.headingMd),
        if (summary.isNotEmpty) ...[
          const SizedBox(width: AppStyling.spaceSm),
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyling.monoSm,
            ),
          ),
        ],
      ],
    );
  }
}

class _ApproveRejectRow extends StatelessWidget {
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ApproveRejectRow({this.onApprove, this.onReject});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton(
          onPressed: onApprove,
          child: const Text('Approve'),
        ),
        const SizedBox(width: AppStyling.spaceSm),
        OutlinedButton(
          onPressed: onReject,
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
