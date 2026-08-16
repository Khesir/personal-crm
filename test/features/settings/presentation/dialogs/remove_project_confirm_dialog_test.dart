import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/settings/presentation/dialogs/remove_project_confirm_dialog.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('RemoveProjectConfirmDialog', () {
    testWidgets('shows the project name in the body text', (tester) async {
      await tester.pumpWidget(_wrap(
        const RemoveProjectConfirmDialog(projectName: 'Avyn'),
      ));

      expect(
        find.textContaining('Remove "Avyn" from Avyn?'),
        findsOneWidget,
      );
      expect(find.textContaining('files on disk are untouched'), findsOneWidget);
    });

    testWidgets('tapping Cancel pops with a falsy result', (tester) async {
      bool? result;

      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const RemoveProjectConfirmDialog(projectName: 'Avyn'),
              );
            },
            child: const Text('open'),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNot(true));
      expect(find.byType(RemoveProjectConfirmDialog), findsNothing);
    });

    testWidgets('tapping Remove pops true', (tester) async {
      bool? result;

      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const RemoveProjectConfirmDialog(projectName: 'Avyn'),
              );
            },
            child: const Text('open'),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(RemoveProjectConfirmDialog), findsNothing);
    });
  });
}
