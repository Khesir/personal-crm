import 'dart:async';

import 'package:crm/core/state/state.dart';
import '../../presentation/state/agent_run_state.dart';
import '../model/agent_event.dart';
import '../model/agent_skill.dart';
import '../repository/agent_run_repository.dart';

class AgentRunController extends StreamState<AgentRunStateData> {
  final AgentRunRepository repository;

  StreamSubscription<AgentEvent>? _subscription;
  Completer<void>? _runCompleter;

  AgentRunController(this.repository) : super(const AgentRunStateData());

  Future<void> start({
    required AgentSkill skill,
    required String repoPath,
    required String projectName,
    Map<String, dynamic>? context,
  }) async {
    emit(AgentRunStateData(
      skill: skill,
      projectName: projectName,
      repoPath: repoPath,
      events: const [],
      status: AgentRunStatus.running,
      startedAt: DateTime.now(),
    ));

    final completer = Completer<void>();
    _runCompleter = completer;
    _subscription = repository
        .run(skill: skill.id, repoPath: repoPath, context: context)
        .listen(
      _handleEvent,
      onError: (Object error) {
        update((current) => current.copyWith(status: AgentRunStatus.error));
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  void _handleEvent(AgentEvent event) {
    update((current) => current.copyWith(events: [...current.events, event]));

    if (event is AgentResult) {
      update((current) => current.copyWith(
            status: event.success ? AgentRunStatus.done : AgentRunStatus.error,
          ));
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    update((current) => current.copyWith(status: AgentRunStatus.stopped));
    if (_runCompleter != null && !_runCompleter!.isCompleted) {
      _runCompleter!.complete();
    }
    _runCompleter = null;
  }

  void background() {
    update((current) => current.copyWith(isBackgrounded: true));
  }

  void foreground() {
    update((current) => current.copyWith(isBackgrounded: false));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
