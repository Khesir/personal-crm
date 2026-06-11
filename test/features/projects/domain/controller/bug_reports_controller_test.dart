import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/projects/domain/controller/bug_reports_controller.dart';
import 'package:crm/features/projects/domain/model/bug_report.dart';
import 'package:crm/features/projects/domain/repository/bug_reports_repository.dart';

class FakeBugReportsRepository implements BugReportsRepository {
  List<BugReport> bugReports;
  int fetchCallCount = 0;

  String? lastUpdateId;
  bool? lastUpdateResolved;

  String? lastDeleteId;

  FakeBugReportsRepository({List<BugReport>? initial}) : bugReports = initial ?? [];

  @override
  Future<List<BugReport>> fetchBugReports() async {
    fetchCallCount++;
    return List.unmodifiable(bugReports);
  }

  @override
  Future<void> updateBugReport(String id, {required bool resolved}) async {
    lastUpdateId = id;
    lastUpdateResolved = resolved;

    bugReports = [
      for (final b in bugReports)
        if (b.id == id)
          BugReport(
            id: b.id,
            severity: b.severity,
            message: b.message,
            stackTrace: b.stackTrace,
            source: b.source,
            resolved: resolved,
            createdAt: b.createdAt,
          )
        else
          b,
    ];
  }

  @override
  Future<void> deleteBugReport(String id) async {
    lastDeleteId = id;
    bugReports = bugReports.where((b) => b.id != id).toList();
  }
}

void main() {
  group('BugReportsController', () {
    test('load() populates state with bug reports from the repository', () async {
      final repo = FakeBugReportsRepository(
        initial: [
          BugReport(
            id: 'b1',
            severity: BugSeverity.error,
            message: 'NullPointerException',
            stackTrace: 'at Foo.bar()',
            source: 'app/foo.dart',
            resolved: false,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );
      final controller = BugReportsController(repo);

      await controller.load();

      expect(controller.data, hasLength(1));
      expect(controller.data!.first.id, 'b1');
      expect(repo.fetchCallCount, 1);

      controller.dispose();
    });

    test('resolve() calls repository with correct id and reloads', () async {
      final repo = FakeBugReportsRepository(
        initial: [
          BugReport(
            id: 'b1',
            severity: BugSeverity.critical,
            message: 'Crash',
            resolved: false,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );
      final controller = BugReportsController(repo);
      await controller.load();

      await controller.resolve('b1');

      expect(repo.lastUpdateId, 'b1');
      expect(repo.lastUpdateResolved, true);
      expect(controller.data!.first.resolved, true);

      controller.dispose();
    });

    test('delete() calls repository with correct id and reloads', () async {
      final repo = FakeBugReportsRepository(
        initial: [
          BugReport(
            id: 'b1',
            severity: BugSeverity.warning,
            message: 'Slow query',
            resolved: false,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );
      final controller = BugReportsController(repo);
      await controller.load();

      await controller.delete('b1');

      expect(repo.lastDeleteId, 'b1');
      expect(controller.data, isEmpty);

      controller.dispose();
    });

    test('filteredBySeverity returns only reports matching the given severity', () async {
      final repo = FakeBugReportsRepository(
        initial: [
          BugReport(
            id: 'b1',
            severity: BugSeverity.error,
            message: 'Error one',
            resolved: false,
            createdAt: DateTime(2024, 1, 1),
          ),
          BugReport(
            id: 'b2',
            severity: BugSeverity.critical,
            message: 'Critical one',
            resolved: false,
            createdAt: DateTime(2024, 1, 1),
          ),
          BugReport(
            id: 'b3',
            severity: BugSeverity.error,
            message: 'Error two',
            resolved: false,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );
      final controller = BugReportsController(repo);
      await controller.load();

      final filtered = controller.filteredBySeverity(BugSeverity.error);

      expect(filtered, hasLength(2));
      expect(filtered.map((b) => b.id), containsAll(['b1', 'b3']));

      controller.dispose();
    });

    test('filteredBySeverity returns all reports when severity is null', () async {
      final repo = FakeBugReportsRepository(
        initial: [
          BugReport(
            id: 'b1',
            severity: BugSeverity.error,
            message: 'Error one',
            resolved: false,
            createdAt: DateTime(2024, 1, 1),
          ),
          BugReport(
            id: 'b2',
            severity: BugSeverity.critical,
            message: 'Critical one',
            resolved: false,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      );
      final controller = BugReportsController(repo);
      await controller.load();

      final filtered = controller.filteredBySeverity(null);

      expect(filtered, hasLength(2));

      controller.dispose();
    });
  });
}
