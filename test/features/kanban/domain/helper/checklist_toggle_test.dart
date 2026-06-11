import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/domain/helper/checklist_toggle.dart';

void main() {
  group('toggleChecklistItem', () {
    test('flips an unchecked item to checked by index', () {
      const body = '''
## Acceptance criteria

- [ ] First item
- [ ] Second item
''';

      final result = toggleChecklistItem(body, 0);

      expect(result, contains('- [x] First item'));
      expect(result, contains('- [ ] Second item'));
    });

    test('flips a checked item back to unchecked by index', () {
      const body = '''
## Acceptance criteria

- [x] First item
- [ ] Second item
''';

      final result = toggleChecklistItem(body, 0);

      expect(result, contains('- [ ] First item'));
      expect(result, contains('- [ ] Second item'));
    });

    test('flips the correct item by index when there are multiple', () {
      const body = '''
## Acceptance criteria

- [ ] First item
- [ ] Second item
- [ ] Third item
''';

      final result = toggleChecklistItem(body, 2);

      expect(result, contains('- [ ] First item'));
      expect(result, contains('- [ ] Second item'));
      expect(result, contains('- [x] Third item'));
    });

    test('only toggles checklist items under "Acceptance criteria" heading', () {
      const body = '''
## Some other section

- [ ] Not a criteria item

## Acceptance criteria

- [ ] Real criteria item
''';

      final result = toggleChecklistItem(body, 0);

      expect(result, contains('- [ ] Not a criteria item'));
      expect(result, contains('- [x] Real criteria item'));
    });

    test('returns body unchanged when index is out of range', () {
      const body = '''
## Acceptance criteria

- [ ] Only item
''';

      final result = toggleChecklistItem(body, 5);

      expect(result, body);
    });
  });
}
