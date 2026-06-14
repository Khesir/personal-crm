import 'package:flutter/material.dart';
import '../../domain/controller/chat_controller.dart';
import '../../domain/model/chat_message.dart';
import '../../domain/model/tool_call.dart';
import '../../domain/model/tool_execution_result.dart';
import '../helpers/tool_call_summary.dart';
import '../widget/reference_confirmation_card.dart';
import '../widget/tool_call_step_card.dart';

/// Renders the step cards for one `assistant` message's `toolCalls`
/// (issue 010): each [ToolCall] paired with its `tool`-role answer if
/// resolved, or a pending step/confirmation card if not.
///
/// Purely a function of [conversationMessages] plus [message] (the
/// assistant message owning [ToolCall.toolCalls]) — re-derives pending state
/// from persisted messages on every build, so reopening a conversation shows
/// the same pending card again.
class AgentStepList extends StatelessWidget {
  final ChatController controller;
  final String conversationId;
  final List<ChatMessage> conversationMessages;
  final ChatMessage message;

  const AgentStepList({
    super.key,
    required this.controller,
    required this.conversationId,
    required this.conversationMessages,
    required this.message,
  });

  /// Whether [message] is the last `assistant` message with `toolCalls` —
  /// only that message's unanswered calls are "pending"; calls in earlier
  /// assistant messages are always considered resolved.
  bool get _isLastToolCallMessage {
    for (final candidate in conversationMessages.reversed) {
      if (candidate.role == ChatRole.assistant && candidate.toolCalls.isNotEmpty) {
        return candidate == message;
      }
    }
    return false;
  }

  ChatMessage? _answerFor(ToolCall call) {
    for (final candidate in conversationMessages) {
      if (candidate.role == ChatRole.tool && candidate.toolCallId == call.id) {
        return candidate;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _isLastToolCallMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final call in message.toolCalls)
          _StepEntry(
            controller: controller,
            conversationId: conversationId,
            call: call,
            answer: _answerFor(call),
            pending: isLast && _answerFor(call) == null,
          ),
      ],
    );
  }
}

class _StepEntry extends StatefulWidget {
  final ChatController controller;
  final String conversationId;
  final ToolCall call;
  final ChatMessage? answer;
  final bool pending;

  const _StepEntry({
    required this.controller,
    required this.conversationId,
    required this.call,
    required this.answer,
    required this.pending,
  });

  @override
  State<_StepEntry> createState() => _StepEntryState();
}

class _StepEntryState extends State<_StepEntry> {
  late Future<_PendingPreview?>? _preview = _maybeLoadPreview();

  Future<_PendingPreview?>? _maybeLoadPreview() {
    if (!widget.pending) return null;
    if (isWriteOrEditTool(widget.call.name)) return null;
    return _loadPreview();
  }

  Future<_PendingPreview?> _loadPreview() async {
    final result =
        await widget.controller.previewPendingToolCall(widget.conversationId, widget.call.id);
    if (result is! ToolReferenceConfirmationNeeded) return _PendingPreview(result, '');

    final projects = await widget.controller.projectsRepository?.getProjects() ?? const [];
    var projectName = result.projectId;
    for (final project in projects) {
      if (project.id == result.projectId) {
        projectName = project.name;
        break;
      }
    }
    return _PendingPreview(result, projectName);
  }

  @override
  void didUpdateWidget(_StepEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pending != widget.pending || oldWidget.answer != widget.answer) {
      _preview = _maybeLoadPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pending) {
      return ToolCallStepCard(
        call: widget.call,
        resultText: widget.answer?.content ?? '',
        writePreview: toolCallWritePreview(widget.call),
      );
    }

    if (isWriteOrEditTool(widget.call.name)) {
      return ToolCallStepCard(
        call: widget.call,
        writePreview: toolCallWritePreview(widget.call),
        onApprove: () => widget.controller.approveToolCall(widget.conversationId, widget.call.id),
        onReject: () => widget.controller.rejectToolCall(widget.conversationId, widget.call.id),
      );
    }

    final preview = _preview;
    if (preview == null) {
      return ToolCallStepCard(call: widget.call);
    }

    return FutureBuilder<_PendingPreview?>(
      future: preview,
      builder: (context, snapshot) {
        final result = snapshot.data?.result;
        if (result is ToolReferenceConfirmationNeeded) {
          return ReferenceConfirmationCard(
            projectName: snapshot.data!.projectName,
            path: result.path,
            onAllow: () => widget.controller.allowReferenceProject(
              widget.conversationId,
              widget.call.id,
              result.projectId,
            ),
            onDeny: () => widget.controller.denyReferenceProject(
              widget.conversationId,
              widget.call.id,
              result.projectId,
            ),
          );
        }
        if (result is ToolWriteProposal) {
          return ToolCallStepCard(
            call: widget.call,
            writePreview: result.preview,
            onApprove: () => widget.controller.approveToolCall(widget.conversationId, widget.call.id),
            onReject: () => widget.controller.rejectToolCall(widget.conversationId, widget.call.id),
          );
        }
        return ToolCallStepCard(call: widget.call);
      },
    );
  }
}

/// A pending non-write tool call's resolved [ToolExecutionResult] plus the
/// reference project's display name, if applicable.
class _PendingPreview {
  final ToolExecutionResult? result;
  final String projectName;

  const _PendingPreview(this.result, this.projectName);
}
