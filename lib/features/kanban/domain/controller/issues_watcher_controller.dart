import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'package:crm/core/state/state.dart';
import 'issues_controller.dart';

typedef DirectoryWatcherFactory = Stream<String> Function(String path);

const _debounceDuration = Duration(milliseconds: 500);

Stream<String> defaultDirectoryWatcherFactory(String path) {
  return DirectoryWatcher(path).events.map((event) => event.path);
}

class IssuesWatcherStateData {
  final bool watching;
  final DateTime? lastSyncedAt;
  final Set<String> changedIds;

  const IssuesWatcherStateData({
    this.watching = false,
    this.lastSyncedAt,
    this.changedIds = const {},
  });

  IssuesWatcherStateData copyWith({
    bool? watching,
    DateTime? lastSyncedAt,
    Set<String>? changedIds,
  }) {
    return IssuesWatcherStateData(
      watching: watching ?? this.watching,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      changedIds: changedIds ?? this.changedIds,
    );
  }
}

class IssuesWatcherController extends StreamState<IssuesWatcherStateData> {
  final IssuesController issuesController;
  final DirectoryWatcherFactory watcherFactory;
  final Duration debounceDuration;

  StreamSubscription<String>? _subscription;
  Timer? _debounceTimer;
  final Set<String> _pendingChangedPaths = {};
  String? _localPath;

  IssuesWatcherController(
    this.issuesController, {
    this.watcherFactory = defaultDirectoryWatcherFactory,
    this.debounceDuration = _debounceDuration,
  }) : super(const IssuesWatcherStateData());

  void start(String localPath) {
    stop();
    _localPath = localPath;

    final issuesDir = p.join(localPath, 'issues');
    try {
      final stream = watcherFactory(issuesDir);
      _subscription = stream.listen(
        _onFileChanged,
        onError: (_) => emit(state.copyWith(watching: false)),
      );
      emit(state.copyWith(watching: true));
    } catch (_) {
      emit(state.copyWith(watching: false));
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingChangedPaths.clear();
    _localPath = null;
  }

  void _onFileChanged(String path) {
    _pendingChangedPaths.add(path);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, _reload);
  }

  Future<void> _reload() async {
    final localPath = _localPath;
    final changedPaths = Set<String>.from(_pendingChangedPaths);
    _pendingChangedPaths.clear();
    if (localPath == null) return;

    await issuesController.refresh(localPath);

    final issues = issuesController.data;
    final changedIds = <String>{};
    if (issues != null) {
      final normalizedChanged = changedPaths.map(p.normalize).toSet();
      for (final issue in issues) {
        if (normalizedChanged.contains(p.normalize(issue.filePath))) {
          changedIds.add(issue.id);
        }
      }
    }

    emit(
      state.copyWith(
        lastSyncedAt: DateTime.now(),
        changedIds: changedIds,
      ),
    );
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
