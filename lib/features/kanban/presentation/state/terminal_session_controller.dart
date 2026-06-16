import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:xterm/xterm.dart';

import 'package:crm/core/state/state.dart';
import '../../domain/repository/terminal_session.dart';

typedef TerminalSessionFactory = TerminalSession Function({
  required String workingDirectory,
  String? shellExecutable,
  List<String> shellArguments,
  Map<String, String> extraEnv,
});

class TerminalTab {
  final String id;
  final String label;
  final String shellLabel;
  final TerminalSession session;
  final Terminal terminal;

  const TerminalTab({
    required this.id,
    required this.label,
    required this.shellLabel,
    required this.session,
    required this.terminal,
  });
}

class TerminalSessionStateData {
  final List<TerminalTab> tabs;
  final String? activeTabId;

  const TerminalSessionStateData({this.tabs = const [], this.activeTabId});

  TerminalSessionStateData copyWith({
    List<TerminalTab>? tabs,
    String? activeTabId,
  }) {
    return TerminalSessionStateData(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
    );
  }

  TerminalTab? get activeTab {
    for (final tab in tabs) {
      if (tab.id == activeTabId) return tab;
    }
    return null;
  }
}

/// Manages the terminal "tabs" (sessions) for a single project's dock
/// Terminal pane. Each tab pairs a [TerminalSession] (the PTY abstraction)
/// with an `xterm` [Terminal] buffer so output persists across tab switches.
class TerminalSessionController extends StreamState<TerminalSessionStateData> {
  final String workingDirectory;
  final TerminalSessionFactory sessionFactory;

  int _nextSessionNumber = 1;
  final List<StreamSubscription<Uint8List>> _subscriptions = [];

  TerminalSessionController({
    required this.workingDirectory,
    required this.sessionFactory,
  }) : super(const TerminalSessionStateData());

  /// Creates a new terminal session/tab with [workingDirectory] as its
  /// working directory, and makes it the active tab.
  TerminalTab createSession({ShellOption? shell}) {
    final id = 'session-$_nextSessionNumber';
    final label = '$_nextSessionNumber';
    _nextSessionNumber++;

    final session = sessionFactory(
      workingDirectory: workingDirectory,
      shellExecutable: shell?.executable,
      shellArguments: shell?.arguments ?? const [],
      extraEnv: shell?.extraEnv ?? const {},
    );
    final terminal = Terminal(maxLines: 10000);
    terminal.onOutput = (data) => session.write(Uint8List.fromList(utf8.encode(data)));
    terminal.onResize = (cols, rows, _, __) => session.resize(cols, rows);

    final subscription = session.output.listen((data) {
      terminal.write(utf8.decode(data, allowMalformed: true));
    });
    _subscriptions.add(subscription);

    final tab = TerminalTab(
      id: id,
      label: label,
      shellLabel: shell?.label ?? '',
      session: session,
      terminal: terminal,
    );

    update((current) => current.copyWith(
          tabs: [...current.tabs, tab],
          activeTabId: id,
        ));

    return tab;
  }

  /// Closes the tab with [tabId], killing its session. If it was the active
  /// tab, focus moves to the nearest remaining tab. No-op if only one tab.
  void closeSession(String tabId) {
    update((current) {
      final tabs = current.tabs;
      if (tabs.length <= 1) return current;
      final index = tabs.indexWhere((t) => t.id == tabId);
      if (index == -1) return current;

      tabs[index].session.kill();

      final remaining = [...tabs]..removeAt(index);
      String? nextActiveId = current.activeTabId;
      if (current.activeTabId == tabId) {
        final nextIndex = (index - 1).clamp(0, remaining.length - 1);
        nextActiveId = remaining[nextIndex].id;
      }
      return current.copyWith(tabs: remaining, activeTabId: nextActiveId);
    });
  }

  /// Switches the active tab to [tabId]. No-op if [tabId] isn't a known tab.
  void switchTab(String tabId) {
    update((current) {
      final exists = current.tabs.any((tab) => tab.id == tabId);
      if (!exists) return current;
      return current.copyWith(activeTabId: tabId);
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    for (final tab in state.tabs) {
      tab.session.kill();
    }
    super.dispose();
  }
}
