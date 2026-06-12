import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm/features/home/di.dart';

void main() {
  group('createChatController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('concurrent first calls return the same singleton instance', () async {
      // Simulate _HomePlaceholder and _HomeSidebar both calling
      // createChatController() in the same frame, before either has
      // resolved.
      final futureA = createChatController();
      final futureB = createChatController();

      final controllerA = await futureA;
      final controllerB = await futureB;

      expect(identical(controllerA, controllerB), isTrue);

      controllerA.dispose();
    });
  });
}
