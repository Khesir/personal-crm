import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:crm/core/state/state.dart';
import 'package:crm/features/settings/domain/controller/projects_controller.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import 'package:crm/features/settings/domain/model/project_metadata.dart';
import 'package:crm/features/settings/domain/repository/project_metadata_repository.dart';
import 'package:crm/features/settings/domain/repository/projects_repository.dart';
import 'package:crm/features/settings/presentation/dialogs/project_form_dialog.dart';

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

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ProjectFormDialog local path field', () {
    testWidgets('is read-only in Add mode', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        pickDirectory: () async => null,
      )));

      // There are two TextFields (name, path); locate the path one directly
      // via its readOnly flag instead — assert no TextField accepting typed
      // input exists other than Name.
      final allTextFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(allTextFields, hasLength(2));
      final readOnlyFields = allTextFields.where((f) => f.readOnly).toList();
      expect(readOnlyFields, hasLength(1), reason: 'exactly one field (path) should be read-only');

      controller.dispose();
    });

    testWidgets('is read-only in Edit mode and pre-filled with the existing path', (tester) async {
      const project = Project(
        id: 'alpha',
        name: 'Alpha',
        localPath: r'C:\repo\alpha',
        projectKey: 'alpha',
      );
      final controller = ProjectsController(FakeProjectsRepository([project]), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        project: project,
        pickDirectory: () async => null,
      )));

      final allTextFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      final readOnlyFields = allTextFields.where((f) => f.readOnly).toList();
      expect(readOnlyFields, hasLength(1));
      expect(find.text(r'C:\repo\alpha'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('typing into the path field is not possible; only the picker changes it', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        pickDirectory: () async => r'C:\picked\path',
      )));

      // The field itself is declared read-only (Flutter's own contract for
      // "cannot be edited by typing" — verified in the tests above), so the
      // only remaining way to change its value is the picker button.
      await tester.tap(find.byIcon(Icons.folder_open_outlined));
      await tester.pumpAndSettle();
      expect(find.text(r'C:\picked\path'), findsOneWidget);

      controller.dispose();
    });
  });

  group('ProjectFormDialog duplicate-path handling', () {
    testWidgets(
      'picking a path already registered to another project shows an inline error and disables Save',
      (tester) async {
        const existing = Project(
          id: 'alpha',
          name: 'Alpha',
          localPath: r'C:\repo\alpha',
          projectKey: 'alpha',
        );
        final controller = ProjectsController(FakeProjectsRepository([existing]), FakeProjectMetadataRepository());
        await controller.load();

        await tester.pumpWidget(_wrap(ProjectFormDialog(
          controller: controller,
          pickDirectory: () async => r'C:\repo\alpha',
        )));

        // Name field: find by absence of readOnly.
        final nameField = find.byWidgetPredicate((w) => w is TextField && !w.readOnly);
        await tester.enterText(nameField, 'Beta');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.folder_open_outlined));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('This folder is already registered as "Alpha"'), findsOneWidget);
        // Dialog must still be open (submit was blocked, not just visually).
        expect(find.byType(ProjectFormDialog), findsOneWidget);
        expect(controller.data, hasLength(1));

        // Save must stay disabled: tapping again does nothing further and no
        // second project gets persisted.
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(controller.data, hasLength(1));

        // Picking a different, non-duplicate path clears the error.
        controller.dispose();
      },
    );

    testWidgets('registering a valid, non-duplicate path still saves and closes the dialog', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
      await controller.load();

      var popped = false;

      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => ProjectFormDialog(
                  controller: controller,
                  pickDirectory: () async => r'C:\repo\gamma',
                ),
              );
              popped = true;
            },
            child: const Text('open'),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final nameField = find.byWidgetPredicate((w) => w is TextField && !w.readOnly);
      await tester.enterText(nameField, 'Gamma');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.folder_open_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(controller.data, hasLength(1));
      expect(controller.data!.first.name, 'Gamma');
      expect(controller.data!.first.localPath, r'C:\repo\gamma');

      controller.dispose();
    });
  });

  group('ProjectFormDialog Create/Open toggle', () {
    testWidgets('Add mode shows the toggle, defaulting to Open existing behavior', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        pickDirectory: () async => null,
      )));

      expect(find.text('Open existing'), findsOneWidget);
      expect(find.text('Create new'), findsOneWidget);
      expect(find.text('Local path'), findsOneWidget);
      expect(find.text('Parent folder'), findsNothing);

      controller.dispose();
    });

    testWidgets('Edit mode does not show the toggle', (tester) async {
      const project = Project(
        id: 'alpha',
        name: 'Alpha',
        localPath: r'C:\repo\alpha',
        projectKey: 'alpha',
      );
      final controller = ProjectsController(FakeProjectsRepository([project]), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        project: project,
        pickDirectory: () async => null,
      )));

      expect(find.text('Open existing'), findsNothing);
      expect(find.text('Create new'), findsNothing);

      controller.dispose();
    });

    testWidgets('switching to Create new swaps the path field for a parent-folder field', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        pickDirectory: () async => null,
      )));

      await tester.tap(find.text('Create new'));
      await tester.pump();

      expect(find.text('Parent folder'), findsOneWidget);
      expect(find.text('Local path'), findsNothing);

      controller.dispose();
    });

    testWidgets('Create mode shows a live preview of <parent>/<slug>/ as name and parent folder are set', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        pickDirectory: () async => r'C:\parent',
      )));

      await tester.tap(find.text('Create new'));
      await tester.pump();

      final nameField = find.byWidgetPredicate((w) => w is TextField && !w.readOnly);
      await tester.enterText(nameField, 'My Project');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.folder_open_outlined));
      await tester.pumpAndSettle();

      final expectedPreview = '${p.join(r'C:\parent', 'my-project')}${p.separator}';
      expect(find.text(expectedPreview), findsOneWidget);

      controller.dispose();
    });
  });

  group('ProjectFormDialog create-new-project flow', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('project_form_dialog_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    testWidgets(
      'confirming Create creates <parent>/<slug>/, scaffolds issues/, registers, and closes the dialog',
      (tester) async {
        final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
        await controller.load();

        var popped = false;
        String? initializedLocalPath;

        await tester.pumpWidget(_wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => ProjectFormDialog(
                    controller: controller,
                    pickDirectory: () async => tempDir.path,
                    // Real dart:io Futures kicked off from a widget callback
                    // never resolve under pumpAndSettle's fake-clock pumping
                    // (verified separately: initializeIssuesFolder's real
                    // behavior is covered end-to-end, without a widget, by
                    // ProjectsController's and IssuesRepositoryImpl's own
                    // tests) — so this fake just records the call.
                    initializeIssuesFolder: (localPath) async {
                      initializedLocalPath = localPath;
                    },
                  ),
                );
                popped = true;
              },
              child: const Text('open'),
            ),
          ),
        ));

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create new'));
        await tester.pump();

        final nameField = find.byWidgetPredicate((w) => w is TextField && !w.readOnly);
        await tester.enterText(nameField, 'Gamma');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.folder_open_outlined));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(popped, isTrue);
        expect(controller.data, hasLength(1));
        final project = controller.data!.first;
        expect(project.name, 'Gamma');
        final expectedPath = p.join(tempDir.path, 'gamma');
        expect(project.localPath, expectedPath);
        expect(Directory(expectedPath).existsSync(), isTrue);
        expect(initializedLocalPath, expectedPath);

        controller.dispose();
      },
    );

    testWidgets(
      'Create mode: picking an icon before Save applies it to the newly-created project',
      (tester) async {
        final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
        await controller.load();

        await tester.pumpWidget(_wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => ProjectFormDialog(
                    controller: controller,
                    pickDirectory: () async => tempDir.path,
                    pickImage: () async => r'C:\Users\me\Pictures\logo.png',
                    initializeIssuesFolder: (localPath) async {},
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ));

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create new'));
        await tester.pump();

        final nameField = find.byWidgetPredicate((w) => w is TextField && !w.readOnly);
        await tester.enterText(nameField, 'Gamma');
        await tester.pump();

        await tester.tap(find.text('Upload'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.folder_open_outlined));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(controller.data, hasLength(1));
        expect(controller.data!.first.iconFileName, 'icon.png');

        controller.dispose();
      },
    );

    testWidgets(
      'a scaffolding failure in initializeIssuesFolder still closes the dialog since the project is already registered',
      (tester) async {
        final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
        await controller.load();

        var popped = false;

        await tester.pumpWidget(_wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => ProjectFormDialog(
                    controller: controller,
                    pickDirectory: () async => tempDir.path,
                    initializeIssuesFolder: (localPath) async {
                      throw Exception('boom');
                    },
                  ),
                );
                popped = true;
              },
              child: const Text('open'),
            ),
          ),
        ));

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create new'));
        await tester.pump();

        final nameField = find.byWidgetPredicate((w) => w is TextField && !w.readOnly);
        await tester.enterText(nameField, 'Gamma');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.folder_open_outlined));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(popped, isTrue);
        expect(controller.data, hasLength(1));
        expect(controller.data!.first.name, 'Gamma');

        controller.dispose();
      },
    );

    testWidgets(
      'folder collision blocks Create with an inline error and creates/registers nothing',
      (tester) async {
        final targetPath = p.join(tempDir.path, 'gamma');
        Directory(targetPath).createSync(recursive: true);

        final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
        await controller.load();

        await tester.pumpWidget(_wrap(ProjectFormDialog(
          controller: controller,
          pickDirectory: () async => tempDir.path,
        )));

        await tester.tap(find.text('Create new'));
        await tester.pump();

        final nameField = find.byWidgetPredicate((w) => w is TextField && !w.readOnly);
        await tester.enterText(nameField, 'Gamma');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.folder_open_outlined));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('A folder named "gamma" already exists here'), findsOneWidget);
        expect(find.byType(ProjectFormDialog), findsOneWidget);
        expect(controller.data, isEmpty);

        // Save stays disabled: tapping again registers nothing further.
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(controller.data, isEmpty);

        controller.dispose();
      },
    );
  });

  group('ProjectFormDialog icon upload', () {
    const project = Project(
      id: 'alpha',
      name: 'Alpha',
      localPath: r'C:\repo\alpha',
      projectKey: 'alpha',
    );

    testWidgets('Add mode also shows the icon field, with no Remove until one is picked', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        pickDirectory: () async => null,
      )));

      expect(find.text('Icon'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);

      controller.dispose();
    });

    testWidgets(
      'Add mode: picking an icon before Save applies it to the project once registered (Open existing)',
      (tester) async {
        final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
        await controller.load();

        await tester.pumpWidget(_wrap(ProjectFormDialog(
          controller: controller,
          pickDirectory: () async => r'C:\repo\gamma',
          pickImage: () async => r'C:\Users\me\Pictures\logo.png',
        )));

        final nameField = find.byWidgetPredicate((w) => w is TextField && !w.readOnly);
        await tester.enterText(nameField, 'Gamma');
        await tester.pump();

        // Icon picked before the project exists: shows a Remove control
        // immediately (pending, local preview) without touching the
        // controller yet.
        await tester.tap(find.text('Upload'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(controller.data, isEmpty);

        await tester.tap(find.byIcon(Icons.folder_open_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(controller.data, hasLength(1));
        expect(controller.data!.first.iconFileName, 'icon.png');

        controller.dispose();
      },
    );

    testWidgets('Add mode: Remove before Save clears the pending selection (never applied)', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository(), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        pickDirectory: () async => r'C:\repo\gamma',
        pickImage: () async => r'C:\Users\me\Pictures\logo.png',
      )));

      final nameField = find.byWidgetPredicate((w) => w is TextField && !w.readOnly);
      await tester.enterText(nameField, 'Gamma');
      await tester.pump();

      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsNothing);

      await tester.tap(find.byIcon(Icons.folder_open_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(controller.data!.first.iconFileName, isNull);

      controller.dispose();
    });

    testWidgets('Edit mode shows Upload and no Remove when no icon is set', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository([project]), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        project: project,
        pickDirectory: () async => null,
      )));

      expect(find.text('Icon'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);

      controller.dispose();
    });

    testWidgets('tapping Upload calls setProjectIcon and the Remove control appears', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository([project]), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        project: project,
        pickDirectory: () async => null,
        pickImage: () async => r'C:\Users\me\Pictures\logo.png',
      )));

      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();

      expect(controller.data!.first.iconFileName, 'icon.png');
      expect(find.byIcon(Icons.close), findsOneWidget);

      controller.dispose();
    });

    testWidgets('cancelling the image picker (returns null) leaves the icon unset', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository([project]), FakeProjectMetadataRepository());
      await controller.load();

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        project: project,
        pickDirectory: () async => null,
        pickImage: () async => null,
      )));

      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();

      expect(controller.data!.first.iconFileName, isNull);
      expect(find.byIcon(Icons.close), findsNothing);

      controller.dispose();
    });

    testWidgets('tapping Remove clears the icon and hides the Remove control again', (tester) async {
      final controller = ProjectsController(FakeProjectsRepository([project]), FakeProjectMetadataRepository());
      await controller.load();
      await controller.setProjectIcon('alpha', r'C:\Users\me\Pictures\logo.png');

      await tester.pumpWidget(_wrap(ProjectFormDialog(
        controller: controller,
        project: controller.data!.first,
        pickDirectory: () async => null,
      )));

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(controller.data!.first.iconFileName, isNull);
      expect(find.byIcon(Icons.close), findsNothing);

      controller.dispose();
    });
  });
}
