import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/shell/presentation/screen/app_shell_screen.dart';

void main() {
  group('shouldActivateProjectFolder', () {
    test('returns true when the injected checker reports the folder exists', () {
      final result = shouldActivateProjectFolder(
        'C:/projects/exists',
        folderExists: (path) => true,
      );

      expect(result, isTrue);
    });

    test('returns false when the injected checker reports the folder is missing', () {
      final result = shouldActivateProjectFolder(
        'C:/projects/missing',
        folderExists: (path) => false,
      );

      expect(result, isFalse);
    });

    test('passes the exact path through to the checker', () {
      String? seenPath;
      shouldActivateProjectFolder(
        'C:/projects/some-project',
        folderExists: (path) {
          seenPath = path;
          return true;
        },
      );

      expect(seenPath, 'C:/projects/some-project');
    });
  });
}
