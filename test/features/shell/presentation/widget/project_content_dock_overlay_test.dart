import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/presentation/state/dock_state.dart';
import 'package:crm/features/shell/presentation/widget/project_content_dock_overlay.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(height: 600, width: 800, child: child),
    ),
  );
}

void main() {
  group('ProjectContentDockOverlay', () {
    testWidgets('renders the dock over the content when showDock is true', (tester) async {
      final controller = DockController();

      await tester.pumpWidget(
        _wrap(
          ProjectContentDockOverlay(
            dockController: controller,
            projectName: 'personal-crm',
            showDock: true,
            content: const ColoredBox(color: Colors.blue, child: Text('Kanban content')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Kanban content'), findsOneWidget);
      expect(find.byIcon(Icons.terminal), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);

      controller.dispose();
    });

    testWidgets('omits the dock when showDock is false', (tester) async {
      final controller = DockController();

      await tester.pumpWidget(
        _wrap(
          ProjectContentDockOverlay(
            dockController: controller,
            projectName: 'personal-crm',
            showDock: false,
            content: const ColoredBox(color: Colors.blue, child: Text('Archived board')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Archived board'), findsOneWidget);
      expect(find.byIcon(Icons.terminal), findsNothing);
      expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);

      controller.dispose();
    });

    testWidgets('content size is unaffected by the dock height', (tester) async {
      final shortDock = DockController();
      final tallDock = DockController();
      tallDock.setHeight(700);

      await tester.pumpWidget(
        _wrap(
          ProjectContentDockOverlay(
            dockController: shortDock,
            projectName: 'personal-crm',
            showDock: true,
            content: const ColoredBox(color: Colors.blue, child: Text('Content')),
          ),
        ),
      );
      await tester.pump();
      final shortSize = tester.getSize(find.text('Content'));

      await tester.pumpWidget(
        _wrap(
          ProjectContentDockOverlay(
            dockController: tallDock,
            projectName: 'personal-crm',
            showDock: true,
            content: const ColoredBox(color: Colors.blue, child: Text('Content')),
          ),
        ),
      );
      await tester.pump();
      final tallSize = tester.getSize(find.text('Content'));

      expect(shortSize, tallSize);

      shortDock.dispose();
      tallDock.dispose();
    });
  });
}
