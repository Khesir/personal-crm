import 'package:flutter/material.dart';
import 'package:crm/core/di/service_locator.dart';
import 'package:crm/core/state/stream_builder_widget.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/agent/api.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import 'package:crm/features/settings/domain/repository/projects_repository.dart';

class ChatPane extends StatefulWidget {
  const ChatPane({super.key});

  @override
  State<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<ChatPane> {
  late final AgentController _controller;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _controller = locator.get<AgentController>();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final repo = locator.get<ProjectsRepository>();
    final projects = await repo.getProjects();
    if (mounted) setState(() => _projects = projects);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _controller.sendMessage(text);
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
      state: _controller,
      builder: (context, state) {
        final header = _Header(
          status: state.status,
          projects: _projects,
          workingProjectName: state.workingProjectName,
          onProjectSelected: (p) => _controller.setWorkingProject(p?.name, p?.localPath),
        );

        if (state.serverStatus == AgentServerStatus.starting) {
          return Column(
            children: [
              header,
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          );
        }

        if (state.serverStatus == AgentServerStatus.failed) {
          return Column(
            children: [
              header,
              const Expanded(
                child: Center(
                  child: Text(
                    'Agent server failed to start. Check that Python and the agent server are available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            header,
            Expanded(child: _Transcript(events: state.events, scrollController: _scrollController)),
            _InputRow(
              controller: _textController,
              disabled: state.status == AgentStatus.running,
              onSend: _send,
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final AgentStatus status;
  final List<Project> projects;
  final String? workingProjectName;
  final void Function(Project?) onProjectSelected;

  const _Header({
    required this.status,
    required this.projects,
    required this.workingProjectName,
    required this.onProjectSelected,
  });

  Color get _dotColor => switch (status) {
        AgentStatus.running => AppColors.warning,
        AgentStatus.error => AppColors.error,
        _ => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text('Agent', style: AppStyling.label),
          const SizedBox(width: AppStyling.spaceSm),
          PopupMenuButton<Project?>(
            tooltip: '',
            offset: const Offset(0, 28),
            onSelected: onProjectSelected,
            itemBuilder: (_) => [
              PopupMenuItem<Project?>(
                value: null,
                child: Text(
                  'No project',
                  style: TextStyle(
                    fontSize: 12,
                    color: workingProjectName == null ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ),
              ...projects.map(
                (p) => PopupMenuItem<Project?>(
                  value: p,
                  child: Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: workingProjectName == p.name ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  workingProjectName ?? 'No project',
                  style: TextStyle(
                    fontSize: 11,
                    color: workingProjectName != null ? AppColors.accent : AppColors.textTertiary,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textTertiary),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
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
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'Send a message to start',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppStyling.spaceMd),
      itemCount: events.length,
      itemBuilder: (context, index) => AgentEventTile(event: events[index]),
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final bool disabled;
  final VoidCallback onSend;

  const _InputRow({
    required this.controller,
    required this.disabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppStyling.spaceSm),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !disabled,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Message agent…',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppStyling.spaceMd,
                  vertical: AppStyling.spaceSm,
                ),
                filled: true,
                fillColor: AppColors.surfaceRaised,
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
                  borderSide: const BorderSide(color: AppColors.accentLine),
                ),
              ),
              onSubmitted: disabled ? null : (_) => onSend(),
            ),
          ),
          const SizedBox(width: AppStyling.spaceXs),
          IconButton(
            onPressed: disabled ? null : onSend,
            icon: const Icon(Icons.send, size: 16),
            color: AppColors.accent,
            disabledColor: AppColors.textFaint,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceRaised,
              padding: const EdgeInsets.all(AppStyling.spaceSm),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }
}
