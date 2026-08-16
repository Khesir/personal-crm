import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/settings/domain/controller/projects_controller.dart';
import 'package:crm/features/settings/domain/helper/project_avatar.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import 'package:crm/features/settings/domain/model/project_metadata.dart';
import 'package:crm/features/settings/domain/repository/project_metadata_repository.dart';
import 'package:crm/features/settings/domain/repository/projects_repository.dart';
import 'package:crm/features/settings/presentation/dialogs/project_form_dialog.dart';
import 'package:crm/features/settings/presentation/dialogs/remove_project_confirm_dialog.dart';
import 'package:crm/features/shell/domain/controller/shell_controller.dart';
import 'package:crm/features/shell/presentation/widget/app_rail.dart';

class FakeProjectsRepository implements ProjectsRepository {
  List<Project> stored;

  FakeProjectsRepository([List<Project>? initial]) : stored = initial ?? [];

  @override
  Future<List<Project>> getProjects() async => List.unmodifiable(stored);

  @override
  Future<void> saveProjects(List<Project> projects) async {
    stored = List.of(projects);
  }
}

class FakeProjectMetadataRepository implements ProjectMetadataRepository {
  final Map<String, ProjectMetadata> store = {};

  @override
  Future<ProjectMetadata> ensureMetadata(
    String localPath, {
    required String id,
    required String name,
  }) async {
    return store.putIfAbsent(localPath, () => ProjectMetadata(id: id, name: name));
  }

  @override
  Future<ProjectMetadata?> readMetadata(String localPath) async => store[localPath];

  @override
  Future<void> writeName(String localPath, String name) async {
    final existing = store[localPath];
    store[localPath] = (existing ?? ProjectMetadata(id: '', name: name)).copyWith(name: name);
  }

  @override
  Future<String> setIcon(String localPath, String sourceImagePath) async => 'icon.png';

  @override
  Future<void> removeIcon(String localPath) async {}
}

const _keepTrack = Project(
  id: 'keep-track',
  name: 'Keep Track',
  localPath: r'C:\repo\keep-track',
  projectKey: 'keep-track',
);

const _avyn = Project(
  id: 'avyn-os',
  name: 'Avyn',
  localPath: r'C:\repo\avyn-os',
  projectKey: 'avyn-os',
);

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(height: 600, width: 800, child: child),
    ),
  );
}

void main() {
  group('AppRail', () {
    late ShellController shellController;
    late ProjectsController projectsController;

    setUp(() async {
      shellController = ShellController();
      projectsController = ProjectsController(
        FakeProjectsRepository([_keepTrack, _avyn]),
        FakeProjectMetadataRepository(),
      );
      await projectsController.load();
    });

    tearDown(() {
      shellController.dispose();
      projectsController.dispose();
    });

    testWidgets('renders one icon per registered project with initials', (tester) async {
      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: projectsController,
      )));
      await tester.pump();

      expect(find.text('KT'), findsOneWidget);
      expect(find.text('AV'), findsOneWidget);
    });

    testWidgets('hovering a rail icon shows a tooltip with the full project name', (tester) async {
      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: projectsController,
      )));
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text('KT')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Keep Track'), findsOneWidget);
    });

    testWidgets('tapping a rail icon sets it as the working project', (tester) async {
      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: projectsController,
      )));
      await tester.pump();

      await tester.tap(find.text('AV'));
      await tester.pump();

      expect(shellController.state.selectedProjectId, 'avyn-os');
      expect(shellController.state.showingSettings, isFalse);
    });

    testWidgets('the "+" button opens the Add Project dialog', (tester) async {
      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: projectsController,
      )));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectFormDialog), findsOneWidget);
      expect(find.text('Add Project'), findsOneWidget);
    });

    testWidgets('the settings gear is pinned at the bottom and opens settings', (tester) async {
      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: projectsController,
      )));
      await tester.pump();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();

      expect(shellController.state.showingSettings, isTrue);
    });

    testWidgets('two different projects get distinct rail colors', (tester) async {
      expect(projectAvatarColor('keep-track'), isNot(projectAvatarColor('avyn-os')));
    });

    testWidgets('right-clicking a rail icon shows Edit, Remove, and Reveal in explorer',
        (tester) async {
      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: projectsController,
      )));
      await tester.pump();

      await tester.tap(find.text('KT'), buttons: kSecondaryButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Reveal in explorer'), findsOneWidget);
    });

    testWidgets('Remove is styled as a warning/destructive action', (tester) async {
      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: projectsController,
      )));
      await tester.pump();

      await tester.tap(find.text('KT'), buttons: kSecondaryButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      final removeText = tester.widget<Text>(find.text('Remove'));
      expect(removeText.style?.color, AppColors.error);
    });

    testWidgets('Edit opens ProjectFormDialog in Edit mode, prefilled with the project',
        (tester) async {
      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: projectsController,
      )));
      await tester.pump();

      await tester.tap(find.text('KT'), buttons: kSecondaryButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectFormDialog), findsOneWidget);
      expect(find.text('Edit Project'), findsOneWidget);
      expect(find.text('Keep Track'), findsOneWidget);
      expect(find.text(r'C:\repo\keep-track'), findsOneWidget);
    });

    testWidgets('Remove opens the confirm dialog; Cancel leaves the project registered',
        (tester) async {
      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: projectsController,
      )));
      await tester.pump();

      await tester.tap(find.text('KT'), buttons: kSecondaryButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.byType(RemoveProjectConfirmDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(RemoveProjectConfirmDialog), findsNothing);
      expect(projectsController.data!.any((p) => p.id == 'keep-track'), isTrue);
    });

    testWidgets('Remove opens the confirm dialog; Confirm unregisters the project',
        (tester) async {
      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: projectsController,
      )));
      await tester.pump();

      await tester.tap(find.text('KT'), buttons: kSecondaryButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();

      expect(find.byType(RemoveProjectConfirmDialog), findsNothing);
      expect(projectsController.data!.any((p) => p.id == 'keep-track'), isFalse);
      // The other project is untouched — no filesystem-wide wipe.
      expect(projectsController.data!.any((p) => p.id == 'avyn-os'), isTrue);
    });

    testWidgets('an empty project list renders no project icons, only "+" and settings',
        (tester) async {
      final emptyProjectsController = ProjectsController(
        FakeProjectsRepository(),
        FakeProjectMetadataRepository(),
      );
      await emptyProjectsController.load();

      await tester.pumpWidget(_wrap(AppRail(
        controller: shellController,
        projectsController: emptyProjectsController,
      )));
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      emptyProjectsController.dispose();
    });
  });
}
