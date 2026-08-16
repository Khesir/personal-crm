import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/features/settings/domain/controller/projects_controller.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import 'package:crm/features/settings/domain/model/project_metadata.dart';
import 'package:crm/features/settings/domain/repository/project_metadata_repository.dart';
import 'package:crm/features/settings/domain/repository/projects_repository.dart';
import 'package:crm/features/settings/presentation/dialogs/remove_project_confirm_dialog.dart';
import 'package:crm/features/settings/presentation/section/projects_section.dart';

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

const _avyn = Project(
  id: 'avyn-os',
  name: 'Avyn',
  localPath: r'C:\repo\avyn-os',
  projectKey: 'avyn-os',
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ProjectsSection delete button', () {
    late ProjectsController controller;

    setUp(() async {
      controller = ProjectsController(FakeProjectsRepository([_avyn]), FakeProjectMetadataRepository());
      await controller.load();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('shows the confirm dialog before removing', (tester) async {
      await tester.pumpWidget(_wrap(ProjectsSection(controller: controller)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(RemoveProjectConfirmDialog), findsOneWidget);
      // Not removed yet: still registered while the dialog is up.
      expect(controller.data!.any((p) => p.id == 'avyn-os'), isTrue);
    });

    testWidgets('Cancel leaves the project registered', (tester) async {
      await tester.pumpWidget(_wrap(ProjectsSection(controller: controller)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(RemoveProjectConfirmDialog), findsNothing);
      expect(controller.data!.any((p) => p.id == 'avyn-os'), isTrue);
    });

    testWidgets('Confirm removes the project', (tester) async {
      await tester.pumpWidget(_wrap(ProjectsSection(controller: controller)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.byType(RemoveProjectConfirmDialog), findsNothing);
      expect(controller.data!.any((p) => p.id == 'avyn-os'), isFalse);
    });
  });
}
