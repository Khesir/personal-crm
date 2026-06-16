import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';
import 'package:crm/features/kanban/presentation/widget/kanban_column.dart';

void main() {
  group('KanbanColumn quick-add', () {
    testWidgets(
      'pressing Enter with non-empty text calls onCreateIssue with the column status and title',
      (tester) async {
        String? createdTitle;
        IssueStatus? createdStatus;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                width: 300,
                child: KanbanColumn(
                  status: IssueStatus.ready,
                  issues: const [],
                  onCreateIssue: (status, title) {
                    createdStatus = status;
                    createdTitle = title;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'New issue title');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(createdStatus, IssueStatus.ready);
        expect(createdTitle, 'New issue title');
      },
    );

    testWidgets(
      'pressing Esc with empty text cancels without calling onCreateIssue',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                width: 300,
                child: KanbanColumn(
                  status: IssueStatus.ready,
                  issues: const [],
                  onCreateIssue: (status, title) {
                    called = true;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(called, isFalse);
        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets(
      'losing focus while empty closes the input without calling onCreateIssue',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    height: 400,
                    width: 300,
                    child: KanbanColumn(
                      status: IssueStatus.ready,
                      issues: const [],
                      onCreateIssue: (status, title) {
                        called = true;
                      },
                    ),
                  ),
                  const TextField(key: Key('other-field')),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNWidgets(2));

        await tester.tap(find.byKey(const Key('other-field')));
        await tester.pumpAndSettle();

        expect(called, isFalse);
        expect(find.byType(TextField), findsOneWidget);
      },
    );
  });
}
