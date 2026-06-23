import 'dart:io';

import 'package:flutter/material.dart';
import 'package:crm/core/state/stream_builder_widget.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/agent/api.dart';
import '../widget/suggested_prompt_chip.dart';

const _kSuggestedPrompts = [
  'Write code',
  'Explain an error',
  'Write a test',
  'Summarize a bug',
  'Draft from an issue',
];

class HomeChatSection extends StatefulWidget {
  final AgentController controller;

  const HomeChatSection({super.key, required this.controller});

  @override
  State<HomeChatSection> createState() => _HomeChatSectionState();
}

class _HomeChatSectionState extends State<HomeChatSection> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final String _userName;

  @override
  void initState() {
    super.initState();
    _userName = Platform.environment['USERNAME'] ?? 'there';
    widget.controller.loadModels();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final message = (text ?? _textController.text).trim();
    if (message.isEmpty) return;
    _textController.clear();
    widget.controller.sendMessage(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamStateBuilder<AgentStateData>(
      state: widget.controller,
      builder: (context, state) {
        final showWelcome = state.events.isEmpty && state.sessionId == null;
        return Container(
          color: AppColors.background,
          child: showWelcome
              ? _WelcomeState(
                  userName: _userName,
                  state: state,
                  textController: _textController,
                  onSend: _send,
                  onSelectModel: widget.controller.selectModel,
                )
              : Column(
                  children: [
                    Expanded(
                      child: _Transcript(events: state.events, scrollController: _scrollController),
                    ),
                    _Composer(
                      compact: true,
                      state: state,
                      textController: _textController,
                      onSend: _send,
                      onSelectModel: widget.controller.selectModel,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _WelcomeState extends StatelessWidget {
  final String userName;
  final AgentStateData state;
  final TextEditingController textController;
  final void Function([String?]) onSend;
  final void Function(String) onSelectModel;

  const _WelcomeState({
    required this.userName,
    required this.state,
    required this.textController,
    required this.onSend,
    required this.onSelectModel,
  });

  String get _statusLine {
    final result = state.modelsResult;
    if (result == null) return '';
    if (result.provider == 'ollama') {
      return 'Connected to Ollama · ${result.models.length} model${result.models.length == 1 ? '' : 's'} ready locally';
    }
    return 'Connected to ${result.provider} · 1 model configured';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 22, color: AppColors.accent),
                const SizedBox(width: AppStyling.spaceSm),
                Text('Welcome back, $userName', style: AppStyling.pageTitle),
              ],
            ),
            if (state.modelsResult != null) ...[
              const SizedBox(height: AppStyling.spaceSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppStyling.spaceXs),
                  Text(_statusLine, style: AppStyling.pageSub),
                ],
              ),
            ],
            const SizedBox(height: AppStyling.spaceXxl),
            _Composer(
              compact: false,
              state: state,
              textController: textController,
              onSend: onSend,
              onSelectModel: onSelectModel,
            ),
            const SizedBox(height: AppStyling.spaceLg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppStyling.spaceSm,
              runSpacing: AppStyling.spaceSm,
              children: [
                for (final prompt in _kSuggestedPrompts)
                  SuggestedPromptChip(label: prompt, onTap: () => onSend(prompt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final bool compact;
  final AgentStateData state;
  final TextEditingController textController;
  final void Function([String?]) onSend;
  final void Function(String) onSelectModel;

  const _Composer({
    required this.compact,
    required this.state,
    required this.textController,
    required this.onSend,
    required this.onSelectModel,
  });

  bool get _disabled => state.status == AgentStatus.running;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.all(AppStyling.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: textController,
            enabled: !_disabled,
            maxLines: compact ? 1 : 3,
            minLines: 1,
            style: AppStyling.bodyLg,
            decoration: InputDecoration(
              hintText: 'What do you want to build or debug today?',
              hintStyle: AppStyling.bodySm,
              border: InputBorder.none,
            ),
            onSubmitted: _disabled ? null : (_) => onSend(),
          ),
          const SizedBox(height: AppStyling.spaceSm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyling.spaceSm,
                  vertical: AppStyling.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentBg,
                  borderRadius: BorderRadius.circular(AppStyling.radiusSm),
                  border: Border.all(color: AppColors.accentLine),
                ),
                child: Text(
                  'Chat',
                  style: AppStyling.label.copyWith(color: AppColors.accentLight),
                ),
              ),
              const Spacer(),
              _ModelPicker(
                modelsResult: state.modelsResult,
                selectedModel: state.selectedModel,
                onSelect: onSelectModel,
              ),
              const SizedBox(width: AppStyling.spaceSm),
              IconButton(
                onPressed: _disabled ? null : () => onSend(),
                icon: const Icon(Icons.send, size: 16),
                color: AppColors.accent,
                disabledColor: AppColors.textFaint,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accentBg,
                  padding: const EdgeInsets.all(AppStyling.spaceSm),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (compact) {
      return Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.all(AppStyling.spaceSm),
        child: box,
      );
    }

    final provider = state.modelsResult?.provider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        box,
        const SizedBox(height: AppStyling.spaceXs),
        if (provider != null)
          Center(
            child: Text(
              provider == 'ollama'
                  ? '● Local · responses generated on-device via Ollama'
                  : '● Cloud · responses generated via $provider',
              style: AppStyling.bodySm.copyWith(color: AppColors.textTertiary),
            ),
          ),
      ],
    );
  }
}

class _ModelPicker extends StatelessWidget {
  final AgentModelsResult? modelsResult;
  final String? selectedModel;
  final void Function(String) onSelect;

  const _ModelPicker({
    required this.modelsResult,
    required this.selectedModel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final models = modelsResult?.models ?? const [];
    AgentModelInfo? current;
    for (final m in models) {
      if (m.name == selectedModel) {
        current = m;
        break;
      }
    }

    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, -8),
      onSelected: onSelect,
      itemBuilder: (_) => [
        for (final m in models)
          PopupMenuItem<String>(
            value: m.name,
            child: Text(
              m.parameterSize.isEmpty ? m.name : '${m.name} · ${m.parameterSize}',
              style: TextStyle(
                fontSize: 12,
                color: m.name == selectedModel ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 12, color: AppColors.accent),
          const SizedBox(width: AppStyling.spaceXs),
          Text(
            current == null
                ? (selectedModel ?? 'No model')
                : current.parameterSize.isEmpty
                    ? current.name
                    : '${current.name} · ${current.parameterSize}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  final List<AgentEvent> events;
  final ScrollController scrollController;

  const _Transcript({required this.events, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppStyling.spaceLg),
      itemCount: events.length,
      itemBuilder: (context, index) => AgentEventTile(event: events[index]),
    );
  }
}
