import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/domain/model/issue.dart';
import 'package:crm/features/kanban/presentation/widget/kanban_column.dart';

const _issue = Issue(
  id: 'issue-001',
  title: 'Add OAuth login',
  feature: 'user-auth',
  status: IssueStatus.ready,
  createdAt: null,
  tags: ['auth'],
  body: 'Body',
  filePath: r'C:\repo\issues\ready\issue-001.md',
);

void main() {
  testWidgets(
    'dragging a card into another column calls onMoveIssue with the target status',
    (tester) async {
      Issue? movedIssue;
      IssueStatus? movedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 400,
                  child: KanbanColumn(
                    status: IssueStatus.ready,
                    issues: const [_issue],
                    onMoveIssue: (issue, status) {
                      movedIssue = issue;
                      movedStatus = status;
                    },
                  ),
                ),
                SizedBox(
                  height: 400,
                  child: KanbanColumn(
                    status: IssueStatus.inprogress,
                    issues: const [],
                    onMoveIssue: (issue, status) {
                      movedIssue = issue;
                      movedStatus = status;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final cardFinder = find.text('Add OAuth login');
      expect(cardFinder, findsOneWidget);

      final cardCenter = tester.getCenter(cardFinder);
      final targetColumnFinder = find.text('No issues');
      final targetCenter = tester.getCenter(targetColumnFinder);

      final gesture = await tester.startGesture(cardCenter);
      await tester.pump(const Duration(milliseconds: 50));

      const steps = 10;
      final dx = (targetCenter.dx - cardCenter.dx) / steps;
      final dy = (targetCenter.dy - cardCenter.dy) / steps;
      for (var i = 0; i < steps; i++) {
        await gesture.moveBy(Offset(dx, dy));
        await tester.pump(const Duration(milliseconds: 16));
      }

      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(movedIssue?.id, _issue.id);
      expect(movedStatus, IssueStatus.inprogress);
    },
  );
}
