import 'data/repository/issues_repository_impl.dart';
import 'data/repository/pty_terminal_session.dart';
import 'domain/controller/issues_controller.dart';
import 'domain/controller/issues_watcher_controller.dart';
import 'domain/repository/issues_repository.dart';
import 'presentation/state/dock_state.dart';
import 'presentation/state/terminal_session_controller.dart';

IssuesController createIssuesController() {
  final repository = IssuesRepositoryImpl();
  return IssuesController(repository);
}

IssuesRepository createIssuesRepository() {
  return IssuesRepositoryImpl();
}

DockController createDockController() => DockController();

IssuesWatcherController createIssuesWatcherController(IssuesController issuesController) {
  return IssuesWatcherController(issuesController);
}

TerminalSessionController createTerminalSessionController(String workingDirectory) {
  return TerminalSessionController(
    workingDirectory: workingDirectory,
    sessionFactory: ({required String workingDirectory, String? shellExecutable, List<String> shellArguments = const [], Map<String, String> extraEnv = const {}}) =>
        PtyTerminalSession(workingDirectory: workingDirectory, shellExecutable: shellExecutable, shellArguments: shellArguments, extraEnv: extraEnv),
  );
}
