import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import '../../domain/model/agent_event.dart';

class AgentEventTile extends StatelessWidget {
  final AgentEvent event;

  const AgentEventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return switch (event) {
      AgentUserMessageEvent(:final text) => AgentUserBubble(text: text),
      AgentTextEvent(:final text) => AgentTextBubble(text: text),
      AgentThinkingEvent(:final text) => AgentCollapsibleTile(label: 'Thinking', content: text),
      AgentToolCallEvent(:final tool, :final input) => AgentCollapsibleTile(
          label: 'Tool: $tool',
          content: input.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
        ),
      AgentToolResultEvent(:final tool, :final output) => AgentCollapsibleTile(
          label: 'Result: $tool',
          content: output,
        ),
      AgentDoneEvent() => const SizedBox.shrink(),
      AgentErrorEvent(:final message) => AgentErrorTile(message: message),
    };
  }
}

class AgentTextBubble extends StatelessWidget {
  final String text;

  const AgentTextBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppStyling.spaceSm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class AgentUserBubble extends StatelessWidget {
  final String text;

  const AgentUserBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppStyling.spaceSm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spaceMd,
          vertical: AppStyling.spaceSm,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentBg,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(color: AppColors.accentLine),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class AgentCollapsibleTile extends StatefulWidget {
  final String label;
  final String content;

  const AgentCollapsibleTile({super.key, required this.label, required this.content});

  @override
  State<AgentCollapsibleTile> createState() => _AgentCollapsibleTileState();
}

class _AgentCollapsibleTileState extends State<AgentCollapsibleTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyling.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppStyling.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyling.spaceMd,
                vertical: AppStyling.spaceXs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: AppStyling.monoSm,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppStyling.spaceMd,
                0,
                AppStyling.spaceMd,
                AppStyling.spaceSm,
              ),
              child: Text(
                widget.content,
                style: AppStyling.monoSm,
              ),
            ),
        ],
      ),
    );
  }
}

class AgentErrorTile extends StatelessWidget {
  final String message;

  const AgentErrorTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyling.spaceSm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyling.spaceMd,
        vertical: AppStyling.spaceSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: AppColors.error),
      ),
    );
  }
}
